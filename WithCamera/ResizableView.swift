import Cocoa

class ResizableView: NSView {
    private let resizableArea: CGFloat = 4
    private var draggedPoint: CGPoint = .zero

    var onMouseMoved: (Bool) -> Void = { _ in }
    var onResize: (CGFloat?, CGFloat?, CursorPosition) -> Void = { (_, _ , _)  in }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        updateTrackingAreas()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateTrackingAreas()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        trackingAreas.forEach { area in
            removeTrackingArea(area)
        }

        addTrackingArea(NSTrackingArea(rect: bounds, options: [ .mouseMoved, .mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let locationInView = convert(event.locationInWindow, from: nil)
        draggedPoint = locationInView
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        draggedPoint = .zero
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let locationInView = convert(event.locationInWindow, from: nil)
        let position = cursorPosition(locationInView)
        onMouseMoved(position != nil)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
//        borderWidth                     = resizableArea
        let locationInView = convert(event.locationInWindow, from: nil)
        let horizontalDistanceDragged = locationInView.x - draggedPoint.x
        let verticalDistanceDragged = locationInView.y - draggedPoint.y

        guard let cursorPosition = cursorPosition(draggedPoint) else { return }

        var width: CGFloat?
        var height: CGFloat?
        if cursorPosition.contains(.top) {
            height = frame.height + verticalDistanceDragged
            draggedPoint = locationInView
        }
        if cursorPosition.contains(.left) {
            width = frame.width - horizontalDistanceDragged
        }
        if cursorPosition.contains(.bottom) {
            height = frame.height - verticalDistanceDragged
        }
        if cursorPosition.contains(.right) {
            width = frame.width + horizontalDistanceDragged
            draggedPoint = locationInView
        }
        onResize(width, height, cursorPosition)
    }

    @discardableResult
    func cursorPosition(_ locationInView: CGPoint) -> CursorPosition? {
        if locationInView.x < resizableArea && locationInView.y < resizableArea {
            if let object = NSCursor.self.perform(Selector(("_windowResizeNorthEastSouthWestCursor"))), let cursor = object.takeUnretainedValue() as? NSCursor {
                cursor.set()
            }
            return [.bottom, .left]
        } else if locationInView.x < resizableArea && locationInView.y > bounds.height - resizableArea {
            if let object = NSCursor.self.perform(Selector(("_windowResizeNorthWestSouthEastCursor"))), let cursor = object.takeUnretainedValue() as? NSCursor {
                cursor.set()
            }
            return [.top, .left]
        } else if locationInView.x > bounds.width - resizableArea && locationInView.y < resizableArea {
            if let object = NSCursor.self.perform(Selector(("_windowResizeNorthWestSouthEastCursor"))), let cursor = object.takeUnretainedValue() as? NSCursor {
                cursor.set()
            }
            return [.bottom, .right]
        } else if locationInView.x > bounds.width - resizableArea && locationInView.y > bounds.height - resizableArea {
            if let object = NSCursor.self.perform(Selector(("_windowResizeNorthEastSouthWestCursor"))), let cursor = object.takeUnretainedValue() as? NSCursor {
                cursor.set()
            }
            return [.top, .right]
        } else if locationInView.x < resizableArea {
            NSCursor.resizeLeftRight.set()
            return .left
        } else if locationInView.x > bounds.width - resizableArea {
            NSCursor.resizeLeftRight.set()
            return .right
        } else if locationInView.y < resizableArea {
            NSCursor.resizeUpDown.set()
            return .bottom
        } else if locationInView.y > bounds.height - resizableArea {
            NSCursor.resizeUpDown.set()
            return .top
        } else {
            NSCursor.arrow.set()
            return nil
        }
    }

    struct CursorPosition: OptionSet {
        let rawValue: Int

        static let top    = CursorPosition(rawValue: 1 << 0)
        static let left  = CursorPosition(rawValue: 1 << 1)
        static let bottom   = CursorPosition(rawValue: 1 << 2)
        static let right   = CursorPosition(rawValue: 1 << 3)
    }
}
