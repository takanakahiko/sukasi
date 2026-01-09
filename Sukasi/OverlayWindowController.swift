import Cocoa

class OverlayWindowController: NSObject {

    private var window: NSWindow?
    private var imageView: NSImageView?

    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    var opacity: Double = 0.35 {
        didSet {
            window?.alphaValue = opacity
        }
    }

    /// Width ratio (0.0 - 1.0), 1.0 = full screen width
    var widthRatio: Double = 1.0 {
        didSet {
            if isVisible {
                updateWindowFrame()
            }
        }
    }

    override init() {
        super.init()
        setupWindow()
    }

    private func setupWindow() {
        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Make it float above all windows
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Transparent background
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false

        // Click-through
        window.ignoresMouseEvents = true

        // Initial opacity
        window.alphaValue = opacity

        // Setup image view
        let imageView = NSImageView(frame: window.contentView?.bounds ?? .zero)
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        window.contentView?.addSubview(imageView)

        self.window = window
        self.imageView = imageView
    }

    @discardableResult
    func loadImage(from path: String) -> Bool {
        guard let image = NSImage(contentsOfFile: path) else {
            return false
        }
        imageView?.image = image
        return true
    }

    func show() {
        updateWindowFrame()
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    private func updateWindowFrame() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let newWidth = screenFrame.width * widthRatio
        let newX = screenFrame.origin.x + (screenFrame.width - newWidth) / 2

        let newFrame = NSRect(
            x: newX,
            y: screenFrame.origin.y,
            width: newWidth,
            height: screenFrame.height
        )

        window?.setFrame(newFrame, display: true)
    }
}
