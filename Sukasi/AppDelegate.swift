import Cocoa
import Carbon

// MARK: - UserDefaults Keys

private enum DefaultsKey: String {
    case overlayVisible
    case opacity
    case widthRatio
    case imagePath
    case hotkeyKeyCode
    case hotkeyModifiers
    case firstLaunch
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var overlayWindowController: OverlayWindowController!
    private var hotkeyManager: HotkeyManager!
    private var hotkeyWindowController: HotkeyWindowController?

    private let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusItem()
        setupOverlayWindow()
        setupHotkey()
        restoreState()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        saveState()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Sukasi") {
                button.image = image
            } else {
                button.title = "透"
            }
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Toggle overlay
        let toggleTitle = overlayWindowController?.isVisible == true ? "Hide Overlay" : "Show Overlay"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleOverlay), keyEquivalent: ""))

        menu.addItem(.separator())

        // Choose image
        menu.addItem(NSMenuItem(title: "Choose Image…", action: #selector(chooseImage), keyEquivalent: ""))

        // Opacity submenu
        let opacityOptions: [(String, Double)] = [
            ("10%", 0.10), ("20%", 0.20), ("35%", 0.35),
            ("50%", 0.50), ("70%", 0.70), ("90%", 0.90)
        ]
        let currentOpacity = overlayWindowController?.opacity ?? 0.35
        menu.addItem(buildSubmenu(
            title: "Opacity",
            options: opacityOptions,
            currentValue: currentOpacity,
            action: #selector(setOpacity(_:))
        ))

        // Width submenu
        let widthOptions: [(String, Double)] = [
            ("25%", 0.25), ("50%", 0.50), ("75%", 0.75), ("100%", 1.00)
        ]
        let currentWidth = overlayWindowController?.widthRatio ?? 1.0
        menu.addItem(buildSubmenu(
            title: "Width",
            options: widthOptions,
            currentValue: currentWidth,
            action: #selector(setWidth(_:))
        ))

        menu.addItem(.separator())

        // Hotkey settings
        menu.addItem(NSMenuItem(title: "Hotkey…", action: #selector(openHotkeySettings), keyEquivalent: ""))

        menu.addItem(.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func buildSubmenu(
        title: String,
        options: [(String, Double)],
        currentValue: Double,
        action: Selector
    ) -> NSMenuItem {
        let submenu = NSMenu()
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menuItem.submenu = submenu

        for (label, value) in options {
            let item = NSMenuItem(title: label, action: action, keyEquivalent: "")
            item.tag = Int(value * 100)
            item.state = abs(currentValue - value) < 0.01 ? .on : .off
            submenu.addItem(item)
        }

        return menuItem
    }

    private func setupOverlayWindow() {
        overlayWindowController = OverlayWindowController()

        // Load image
        if let savedPath = defaults.string(forKey: .imagePath),
           FileManager.default.fileExists(atPath: savedPath) {
            overlayWindowController.loadImage(from: savedPath)
        } else if let bundleImage = Bundle.main.path(forResource: "default_overlay", ofType: "png") {
            overlayWindowController.loadImage(from: bundleImage)
        }
    }

    private func setupHotkey() {
        hotkeyManager = HotkeyManager()

        let keyCode: UInt32
        let modifiers: UInt32

        if defaults.object(forKey: DefaultsKey.hotkeyKeyCode.rawValue) != nil {
            keyCode = UInt32(defaults.integer(forKey: .hotkeyKeyCode))
            modifiers = UInt32(defaults.integer(forKey: .hotkeyModifiers))
        } else {
            // Default: ⌥⌘H
            keyCode = UInt32(kVK_ANSI_H)
            modifiers = UInt32(optionKey | cmdKey)
        }

        registerHotkey(keyCode: keyCode, modifiers: modifiers)
    }

    private func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        hotkeyManager.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
            self?.toggleOverlay()
        }
    }

    private func restoreState() {
        // First launch: set defaults
        if !defaults.bool(forKey: .firstLaunch) {
            defaults.set(true, forKey: .firstLaunch)
            defaults.set(false, forKey: .overlayVisible)
            defaults.set(0.35, forKey: .opacity)
            defaults.set(1.0, forKey: .widthRatio)
            return
        }

        // Restore opacity
        let opacity = defaults.double(forKey: .opacity)
        if opacity > 0 {
            overlayWindowController.opacity = opacity
        }

        // Restore width ratio
        let widthRatio = defaults.double(forKey: .widthRatio)
        if widthRatio > 0 {
            overlayWindowController.widthRatio = widthRatio
        }

        // Restore visibility
        if defaults.bool(forKey: .overlayVisible) {
            overlayWindowController.show()
        }

        updateMenu()
    }

    private func saveState() {
        defaults.set(overlayWindowController.isVisible, forKey: .overlayVisible)
        defaults.set(overlayWindowController.opacity, forKey: .opacity)
        defaults.set(overlayWindowController.widthRatio, forKey: .widthRatio)
    }

    // MARK: - Actions

    @objc private func toggleOverlay() {
        overlayWindowController.toggle()
        updateMenu()
        saveState()
    }

    @objc private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .bmp]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if overlayWindowController.loadImage(from: url.path) {
                defaults.set(url.path, forKey: .imagePath)
            }
        }
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        overlayWindowController.opacity = Double(sender.tag) / 100.0
        updateMenu()
        saveState()
    }

    @objc private func setWidth(_ sender: NSMenuItem) {
        overlayWindowController.widthRatio = Double(sender.tag) / 100.0
        updateMenu()
        saveState()
    }

    @objc private func openHotkeySettings() {
        if hotkeyWindowController == nil {
            hotkeyWindowController = HotkeyWindowController(
                hotkeyManager: hotkeyManager,
                onSave: { [weak self] keyCode, modifiers in
                    guard let self = self else { return }
                    self.defaults.set(Int(keyCode), forKey: .hotkeyKeyCode)
                    self.defaults.set(Int(modifiers), forKey: .hotkeyModifiers)
                    self.registerHotkey(keyCode: keyCode, modifiers: modifiers)
                }
            )
        }
        hotkeyWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - UserDefaults Extension

private extension UserDefaults {
    func string(forKey key: DefaultsKey) -> String? {
        string(forKey: key.rawValue)
    }

    func bool(forKey key: DefaultsKey) -> Bool {
        bool(forKey: key.rawValue)
    }

    func integer(forKey key: DefaultsKey) -> Int {
        integer(forKey: key.rawValue)
    }

    func double(forKey key: DefaultsKey) -> Double {
        double(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: DefaultsKey) {
        set(value, forKey: key.rawValue)
    }
}
