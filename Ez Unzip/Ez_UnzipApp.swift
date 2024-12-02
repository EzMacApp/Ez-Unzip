//
//  Ez_UnzipApp.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/27.
//

import KeyboardShortcuts
import SwiftUI

@main
struct Ez_UnzipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var mainWindow: NSWindow? // 主窗口引用
    var settingsWindowController: NSWindowController? // 设置窗口控制器
    var taskHelper = TaskHelper.shard

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "archivebox", accessibilityDescription: nil)
        }

        //初始化菜单
        setupMenu()
        
        // 初始化主窗口
        setupMainWindow()

        // 注册全局快捷键
        setupGlobalShortcuts()
    }

    func createMenuItem(imageName: String, action: Selector, keyEquivalent: String = "", modifierMask: NSEvent.ModifierFlags = []) -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        menuItem.action = action
        menuItem.target = self
        menuItem.title = ""
        menuItem.keyEquivalent = keyEquivalent
        menuItem.keyEquivalentModifierMask = modifierMask
        return menuItem
    }

    func setupMenu() {
        // 设置菜单
        let menu = NSMenu()
        // 添加菜单项：主窗口
        menu.addItem(createMenuItem(imageName: "macwindow", action: #selector(openMainWindow), keyEquivalent: "m", modifierMask: [.control, .command]))

        // 添加菜单项：设置窗口
        menu.addItem(createMenuItem(imageName: "gear", action: #selector(openSettingsWindow), keyEquivalent: "s", modifierMask: [.control, .command]))

        // 分隔线
        menu.addItem(NSMenuItem.separator())

        // 添加菜单项：退出应用
        menu.addItem(createMenuItem(imageName: "power", action: #selector(quitApp), keyEquivalent: "q", modifierMask: [.command]))

        statusItem.menu = menu
    }

    func setupMainWindow() {
        let mainView = ContentView()
        let hostingController = NSHostingController(rootView: mainView)
        mainWindow = NSWindow(
            contentViewController: hostingController
        )
        mainWindow?.title = "Ez Unzip"
        mainWindow?.setContentSize(NSSize(width: 600, height: 400))
        mainWindow?.styleMask = [.titled, .closable, .resizable, .miniaturizable]
    }

    @objc func openMainWindow() {
        // 显示主窗口并居中
        if let mainWindow = mainWindow {
            centerWindow(mainWindow)
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true) // 激活应用
        }
    }

    @objc func openSettingsWindow() {
        // 如果设置窗口已经存在，则直接激活
        if let windowController = settingsWindowController {
            windowController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 创建新的设置窗口控制器
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(
            contentViewController: hostingController
        )
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 300))

        let windowController = NSWindowController(window: window)
        settingsWindowController = windowController

        // 居中设置窗口并显示
        centerWindow(window)
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // 居中窗口
    func centerWindow(_ window: NSWindow) {
        if let screen = window.screen {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.origin.x + (screenFrame.size.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.size.height - windowSize.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func setupGlobalShortcuts() {
        // 设置压缩快捷键
        KeyboardShortcuts.onKeyUp(for: .compress) {
            if let fileURL = self.taskHelper.getSelectedFileFromFinder() {
                let outputURL = fileURL.deletingLastPathComponent() // 保存到原目录
                let compressedFileURL = outputURL.appendingPathComponent("\(fileURL.lastPathComponent).zip")
                if FileManager.default.fileExists(atPath: compressedFileURL.path) {
                    var statusMessage = "File already compressed: \(compressedFileURL.lastPathComponent)"
                    return
                }

                self.taskHelper.compressToZip(input: fileURL, output: outputURL)
            }
        }

        // 设置解压快捷键
        KeyboardShortcuts.onKeyUp(for: .decompress) {
            if let fileURL = self.taskHelper.getSelectedFileFromFinder() {
                let outputURL = fileURL.deletingLastPathComponent() // 保存到原目录
                self.taskHelper.decompressFile(input: fileURL, output: outputURL)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .openMain) {
            self.openMainWindow()
        }

        KeyboardShortcuts.onKeyUp(for: .openSetting) {
            self.openSettingsWindow()
        }
    }
}
