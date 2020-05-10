import Cocoa
import WebKit
import Quartz.QuickLookUI
import AVFoundation

final class ViewController: NSViewController {
    @IBOutlet private var textField: NSTextField!

    @IBOutlet private var webView: WKWebView!
    private let urlSession = URLSession(configuration: .default)

    @IBOutlet private var previewViewContainer: NSView!
    private var previewView = QLPreviewView(frame: .zero, style: .compact)!

    @IBOutlet private var dragDropView: DragDropView!

    @IBOutlet private var videoCaptureViewContainer: ResizableView!
    @IBOutlet private var videoCaptureViewContainerTrailing: NSLayoutConstraint!
    @IBOutlet private var videoCaptureViewContainerBottom: NSLayoutConstraint!
    @IBOutlet private var videoCaptureView: NSView!
    @IBOutlet private var videoCaptureViewHeight: NSLayoutConstraint!

    private let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = .white

        webView.isHidden = true
        webView.navigationDelegate = self

        previewView.isHidden = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewViewContainer.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: previewViewContainer.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: previewViewContainer.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: previewViewContainer.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: previewViewContainer.bottomAnchor),
        ])

        dragDropView.onDrop = { [weak self] in
            self?.showFilePreview($0)
        }

        videoCaptureViewContainer.wantsLayer = true
        videoCaptureViewContainer.layer?.masksToBounds = false
        videoCaptureViewContainer.layer?.shadowColor = .black
        videoCaptureViewContainer.layer?.shadowOpacity = 0.2
        videoCaptureViewContainer.layer?.shadowRadius = 6
        videoCaptureViewContainer.layer?.shadowOffset = CGSize(width: 0, height: -2)

        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        videoCaptureViewContainer.addGestureRecognizer(panGestureRecognizer)

        videoCaptureViewContainer.onMouseMoved = {
            panGestureRecognizer.isEnabled = !$0
        }
        videoCaptureViewContainer.onResize = { [weak self] (width, height, cursorPosition) in
            guard let self = self else { return }

            if let width = width {
                if cursorPosition.contains(.right) {
                    self.videoCaptureViewContainerTrailing.constant -= width - self.videoCaptureViewHeight.constant * (16 / 9)
                }
                self.videoCaptureViewHeight.constant = width * (9 / 16)
            }
            if let height = height {
                if cursorPosition.contains(.bottom) {
                    self.videoCaptureViewContainerBottom.constant -= height - self.videoCaptureViewHeight.constant
                }
                self.videoCaptureViewHeight.constant = height
            }
        }

        videoCaptureView.wantsLayer = true
        videoCaptureView.layer?.cornerRadius = 6

        if let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = captureSession
        if let layer = videoCaptureView.layer {
            previewLayer.frame = layer.bounds
            layer.addSublayer(previewLayer)
        }

        captureSession.startRunning()
    }

    @IBAction
    private func textFieldAction(_ sender: NSTextField) {
        webView.isHidden = false

        if var components = URLComponents(string: sender.stringValue) {
            components.scheme = "https"
            if let url = components.url {
                let request = URLRequest(url: url)
                urlSession.dataTask(with: url) { [weak self] (data, response, error) in
                    DispatchQueue.main.async {
                        if let _ = error {
                            var components = URLComponents(string: "https://www.google.com/search")
                            components?.queryItems = [URLQueryItem(name: "q", value: sender.stringValue)]
                            if let url = components?.url {
                                self?.loadWebView(URLRequest(url: url))
                            }
                        } else {
                            self?.loadWebView(request)
                        }
                    }
                }
                .resume()
            }
        }
    }

    private func loadWebView(_ request: URLRequest) {
        webView.isHidden = false
        previewView.isHidden = true
        webView.load(request)
    }

    @IBAction
    private func browseFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel();

        openPanel.showsResizeIndicator = true;
        openPanel.showsHiddenFiles = false;
        openPanel.canChooseDirectories = false;
        openPanel.canCreateDirectories = false;
        openPanel.allowsMultipleSelection = false;

        openPanel.beginSheetModal(for: view.window!) { [weak self] (response) in
            if response == .OK, let url = openPanel.url {
                self?.showFilePreview(url)
            }
        }
    }

    private func showFilePreview(_ url: URL) {
        webView.isHidden = true
        previewView.isHidden = false
        previewView.previewItem = PreviewItem(url: url)
    }

    @objc
    private func handlePanGesture(_ sender: NSPanGestureRecognizer) {
        guard NSCursor.current == NSCursor.arrow else { return }
        
        let translation = sender.translation(in: view)
        switch sender.state {
        case .possible, .began:
            break
        case .changed:
            videoCaptureViewContainerTrailing.constant -= translation.x
            videoCaptureViewContainerBottom.constant += translation.y
        case .ended, .cancelled, .failed:
            break
        @unknown default:
            break
        }
        sender.setTranslation(.zero, in: view)
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let absoluteString = webView.url?.absoluteString {
            textField.stringValue = absoluteString
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: view.window!)
    }
}
