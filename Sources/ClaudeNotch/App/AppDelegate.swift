import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let sessionManager = SessionManager()
    var notchController: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 安装/更新 hooks（幂等）
        HookInstaller.installIfNeeded()

        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "ClaudeNotch")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Notch", action: #selector(showNotch), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Notch", action: #selector(hideNotch), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ClaudeNotch", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        // 初始化
        notchController = NotchController(sessionManager: sessionManager)
        notchController?.setup()
        sessionManager.start()

        // 启动时紧凑模式，悬停刘海展开
        Task {
            await notchController?.showCompact()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        sessionManager.stop()
    }

    @objc func showNotch() {
        Task { await notchController?.showExpanded() }
    }

    @objc func hideNotch() {
        Task { await notchController?.hide() }
    }

    @objc func quitApp() {
        sessionManager.stop()
        NSApp.terminate(nil)
    }
}
