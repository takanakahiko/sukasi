import Cocoa
import Carbon

class HotkeyWindowController: NSWindowController {

    private let hotkeyManager: HotkeyManager
    private let onSave: (UInt32, UInt32) -> Void

    private var hotkeyField: NSTextField!
    private var statusLabel: NSTextField!

    private var capturedKeyCode: UInt32 = 0
    private var capturedModifiers: UInt32 = 0

    private var eventMonitor: Any?

    init(hotkeyManager: HotkeyManager, onSave: @escaping (UInt32, UInt32) -> Void) {
        self.hotkeyManager = hotkeyManager
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Change Hotkey"
        window.center()

        super.init(window: window)

        setupUI()
        updateHotkeyDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeEventMonitor()
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Label
        let label = NSTextField(labelWithString: "Press new hotkey:")
        label.frame = NSRect(x: 20, y: 110, width: 260, height: 20)
        contentView.addSubview(label)

        // Hotkey field
        hotkeyField = NSTextField(frame: NSRect(x: 20, y: 75, width: 260, height: 30))
        hotkeyField.isEditable = false
        hotkeyField.isSelectable = false
        hotkeyField.alignment = .center
        hotkeyField.font = NSFont.systemFont(ofSize: 16)
        hotkeyField.placeholderString = "Click and press keys"
        contentView.addSubview(hotkeyField)

        // Status label
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 20, y: 50, width: 260, height: 20)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        contentView.addSubview(statusLabel)

        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAction))
        cancelButton.frame = NSRect(x: 110, y: 10, width: 80, height: 30)
        cancelButton.bezelStyle = .rounded
        contentView.addSubview(cancelButton)

        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveAction))
        saveButton.frame = NSRect(x: 200, y: 10, width: 80, height: 30)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        contentView.addSubview(saveButton)

        window?.makeFirstResponder(contentView)
    }

    private func updateHotkeyDisplay() {
        let keyCode = capturedKeyCode > 0 ? capturedKeyCode : hotkeyManager.currentKeyCode
        let modifiers = capturedKeyCode > 0 ? capturedModifiers : hotkeyManager.currentModifiers

        if keyCode > 0 || modifiers > 0 {
            hotkeyField.stringValue = HotkeyManager.stringFromKeyCode(keyCode, modifiers: modifiers)
        } else {
            hotkeyField.stringValue = ""
        }
    }

    private func setStatus(_ message: String, color: NSColor) {
        statusLabel.stringValue = message
        statusLabel.textColor = color
    }

    // MARK: - Event Monitor

    private func installEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Window Lifecycle

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        capturedKeyCode = 0
        capturedModifiers = 0
        statusLabel.stringValue = ""
        updateHotkeyDisplay()
        installEventMonitor()
    }

    override func close() {
        removeEventMonitor()
        super.close()
    }

    // MARK: - Key Event Handling

    private func handleKeyEvent(_ event: NSEvent) {
        guard window?.isKeyWindow == true else { return }

        let modifiers = HotkeyManager.carbonModifiersFromNSEvent(event.modifierFlags)

        // Require at least Command or Control
        guard modifiers & UInt32(cmdKey) != 0 || modifiers & UInt32(controlKey) != 0 else {
            setStatus("Use ⌘ or ⌃ modifier", color: .systemOrange)
            return
        }

        capturedKeyCode = UInt32(event.keyCode)
        capturedModifiers = modifiers
        updateHotkeyDisplay()
        setStatus("Press Save to apply", color: .systemGreen)
    }

    // MARK: - Actions

    @objc private func saveAction() {
        guard capturedKeyCode > 0 else {
            setStatus("Please press a hotkey first", color: .systemRed)
            return
        }

        onSave(capturedKeyCode, capturedModifiers)
        close()
    }

    @objc private func cancelAction() {
        close()
    }
}
