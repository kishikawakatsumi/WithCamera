import Cocoa
import WebKit
import Quartz.QuickLookUI
import AVFoundation

final class ViewController: NSViewController {
    @IBOutlet private var textField: NSTextField!
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var previewViewContainer: NSView!
    private var previewView = QLPreviewView(frame: .zero, style: .compact)!
    @IBOutlet private var dragDropView: DragDropView!

    @IBOutlet private var videoCaptureView: NSView!
    @IBOutlet private var videoCaptureViewTrailing: NSLayoutConstraint!
    @IBOutlet private var videoCaptureViewBottom: NSLayoutConstraint!
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewViewContainer.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: previewViewContainer.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: previewViewContainer.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: previewViewContainer.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: previewViewContainer.bottomAnchor),
        ])

        dragDropView.onDrop = { [weak self] in
            self?.previewView.previewItem = PreviewItem(url: $0)
        }

        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        videoCaptureView.addGestureRecognizer(panGestureRecognizer)

        videoCaptureView.wantsLayer = true

        if let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input) {
            session.addInput(input)
        }

        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.session = session
        if let layer = videoCaptureView.layer {
            previewLayer.frame = layer.bounds
            layer.addSublayer(previewLayer)
        }

        session.startRunning()
    }

    @IBAction
    private func textFieldAction(_ sender: NSTextField) {
        if let url = URL(string: sender.stringValue) {
            webView.load(URLRequest(url: url))
        }
    }

    @IBAction
    private func browseFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel();

        openPanel.showsResizeIndicator    = true;
        openPanel.showsHiddenFiles        = false;
        openPanel.canChooseDirectories    = false;
        openPanel.canCreateDirectories    = false;
        openPanel.allowsMultipleSelection = false;

        openPanel.beginSheetModal(for: view.window!) { [weak self] (response) in
            if response == .OK, let url = openPanel.url {
                self?.previewView.previewItem = PreviewItem(url: url)
            }
        }
    }

    @objc
    func handlePanGesture(_ sender: NSPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        switch sender.state {
        case .possible, .began:
            break
        case .changed:
            videoCaptureViewTrailing.constant -= translation.x
            videoCaptureViewBottom.constant += translation.y
        case .ended, .cancelled, .failed:
            break
        @unknown default:
            break
        }
        sender.setTranslation(.zero, in: view)
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: view.window!)
    }
}

final class DragDropView: NSView {
    var onDrop: (URL) -> Void = { _ in }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        registerForDraggedTypes([.URL, .fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = pasteboard[0] as? String else { return false }

        onDrop(URL(fileURLWithPath: path))

        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

final class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL
    var previewItemTitle: String

    init(url: URL, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title ?? url.lastPathComponent
    }
}
