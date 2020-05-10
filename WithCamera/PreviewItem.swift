import Quartz.QuickLookUI

final class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL
    var previewItemTitle: String

    init(url: URL, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title ?? url.lastPathComponent
    }
}
