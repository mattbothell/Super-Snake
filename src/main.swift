import Cocoa
import WebKit

// Native macOS shell for the Snake game. The game itself lives in Snake.html
// (bundled in Resources). Two JavaScript bridges connect it to the app:
//   "store" — settings and high scores, persisted in UserDefaults
//   "win"   — window shape: a normal titled window for the Classic theme, or a
//             borderless, transparent window shaped like the phone / monitor.

// "Snake" or "Super Snake", from Info.plist (set by build.sh).
let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Snake"

final class GameWindow: NSWindow {
    // Borderless windows can't take keyboard focus unless we allow it.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class GameWebView: WKWebView {
    // Set from the page while the pointer is over the device's case.
    var dragEnabled = false

    override func mouseDown(with event: NSEvent) {
        if dragEnabled, let window = window {
            window.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class Bridge: NSObject, WKScriptMessageHandler {
    static let prefix = "store."
    weak var app: AppDelegate?

    static func snapshot() -> [String: String] {
        var dict: [String: String] = [:]
        for (key, value) in UserDefaults.standard.dictionaryRepresentation()
        where key.hasPrefix(prefix) {
            if let s = value as? String { dict[String(key.dropFirst(prefix.count))] = s }
        }
        return dict
    }

    static func snapshotJSON() -> String {
        let data = (try? JSONSerialization.data(withJSONObject: snapshot())) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if message.name == "store" {
            guard let key = body["key"] as? String, let value = body["value"] as? String else { return }
            UserDefaults.standard.set(value, forKey: Bridge.prefix + key)
            return
        }
        guard let app = app else { return }
        switch body["cmd"] as? String {
        case "layout":
            let theme = body["theme"] as? String ?? "classic"
            let w = (body["width"] as? NSNumber)?.doubleValue ?? 680
            let h = (body["height"] as? NSNumber)?.doubleValue ?? 760
            app.layout(theme: theme, size: NSSize(width: w, height: h))
        case "drag":
            app.webView.dragEnabled = body["enabled"] as? Bool ?? false
        case "close":
            app.closeWindow()
        case "minimize":
            app.minimizeWindow()
        default:
            break
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: GameWindow!
    var webView: GameWebView!
    let bridge = Bridge()
    var shown = false
    var currentTheme = ""
    var classicSize = NSSize(width: 680, height: 760)

    static let classicMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
    static let deviceMask: NSWindow.StyleMask = [.borderless, .miniaturizable]
    static let classicBackground = NSColor(red: 0x0b/255, green: 0x0d/255, blue: 0x10/255, alpha: 1)

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        bridge.app = self

        let content = WKUserContentController()
        content.add(bridge, name: "store")
        content.add(bridge, name: "win")
        content.addUserScript(WKUserScript(
            source: "window.__nativeStore = \(Bridge.snapshotJSON());",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.userContentController = content

        webView = GameWebView(frame: NSRect(x: 0, y: 0, width: 680, height: 760), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.underPageBackgroundColor = .clear

        let theme = savedTheme()
        window = GameWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 760),
            styleMask: theme == "classic" ? AppDelegate.classicMask : AppDelegate.deviceMask,
            backing: .buffered, defer: false)
        window.title = appName
        window.isReleasedWhenClosed = false
        window.contentView = webView
        applyChrome(theme)

        if let url = Bundle.main.url(forResource: "Snake", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        // The page reports its size once rendered; show the window then (or after a moment regardless).
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.showIfNeeded() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func savedTheme() -> String {
        guard let json = Bridge.snapshot()["snake.settings"],
              let obj = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let theme = obj["theme"] as? String else { return "classic" }
        return theme
    }

    private func applyChrome(_ theme: String) {
        if theme == "classic" {
            window.styleMask = AppDelegate.classicMask
            window.isOpaque = true
            window.backgroundColor = AppDelegate.classicBackground
            window.minSize = NSSize(width: 480, height: 560)
            window.title = appName
        } else {
            window.styleMask = AppDelegate.deviceMask
            window.isOpaque = false
            window.backgroundColor = .clear
            window.minSize = .zero
        }
        window.hasShadow = true
    }

    func layout(theme: String, size: NSSize) {
        if currentTheme == "classic" && shown {
            classicSize = window.contentRect(forFrameRect: window.frame).size
        }
        let old = window.frame
        applyChrome(theme)

        let contentSize = theme == "classic" ? classicSize : size
        let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        // Keep the window's top edge and horizontal center where they were.
        var frame = NSRect(x: old.midX - frameSize.width / 2, y: old.maxY - frameSize.height,
                           width: frameSize.width, height: frameSize.height)
        if let visible = (window.screen ?? NSScreen.main)?.visibleFrame {
            frame.origin.x = min(max(frame.minX, visible.minX), visible.maxX - frame.width)
            frame.origin.y = min(max(frame.minY, visible.minY), visible.maxY - frame.height)
        }
        window.setFrame(frame, display: true)
        currentTheme = theme
        webView.dragEnabled = false

        if !shown { window.center() }
        showIfNeeded()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)
        // The shadow of a transparent window follows what's drawn, so recompute it once the page has painted.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.window.invalidateShadow() }
    }

    private func showIfNeeded() {
        guard !shown else { return }
        shown = true
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func closeWindow() { window.close() }
    @objc func minimizeWindow() { window.miniaturize(nil) }

    private func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let windowItem = NSMenuItem()
        main.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(minimizeWindow), keyEquivalent: "m").target = self
        windowMenu.addItem(withTitle: "Close", action: #selector(closeWindow), keyEquivalent: "w").target = self
        windowItem.submenu = windowMenu

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
