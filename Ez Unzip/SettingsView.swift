//
//  SettingsView.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/29.
//

import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var defaultCompressionFormat = "zip" // 默认压缩格式
    let compressionFormats = ["zip", "tar", "gz"]
    @State private var sameUnZipFolder = false
    @State private var showDockIcon = true // 是否显示 Dock 图标

    var body: some View {
        VStack(alignment: .leading) {
            // 快捷键设置
            HStack(alignment: .center, spacing: 30) {
                Image(systemName: "command")
                    .resizable()
                    .frame(width: 24, height: 24)

                VStack {
                    HStack {
                        Image(systemName: "archivebox.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                        KeyboardShortcuts.Recorder(for: .decompress)
                    }

                    HStack {
                        Image(systemName: "archivebox.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                        KeyboardShortcuts.Recorder(for: .compress)
                    }
                }
            }
            Divider().padding(.vertical)

            // 默认压缩格式设置
            HStack(alignment: .center, spacing: 30) {
                Image(systemName: "document")
                    .resizable()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "archivebox.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Picker("", selection: $defaultCompressionFormat) {
                            ForEach(compressionFormats, id: \.self) { format in
                                Text(format.uppercased()).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack(alignment: .top) {
                        Image(systemName: sameUnZipFolder ? "folder.circle.fill" : "folder.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Toggle("", isOn: $sameUnZipFolder)
                            .onChange(of: sameUnZipFolder) { _ in
//                                                        LaunchAtLogin.isEnabled = newValue
                            }.toggleStyle(.checkbox)
                    }
                }
            }

            Divider().padding(.vertical)

            // 开机启动设置
            HStack(alignment: .center, spacing: 30) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Image(systemName: launchAtLoginEnabled ? "power.circle.fill" : "power.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Toggle("", isOn: $launchAtLoginEnabled)
                            .onChange(of: launchAtLoginEnabled) { newValue in
                                LaunchAtLogin.isEnabled = newValue

                            }.toggleStyle(.checkbox)
                    }
                    // 是否显示 Dock 图标
                    HStack(alignment: .top) {
                        Image(systemName: showDockIcon ? "eye.circle.fill" : "eye.slash.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Toggle("", isOn: $showDockIcon)
                            .onChange(of: showDockIcon) { newValue in
                                toggleDockIconVisibility(show: newValue)
                            }
                            .toggleStyle(.checkbox)
                    }
                }
            }
        }
        .padding()
        .frame(width: 320, height: 280)
        .onAppear {
            loadSettings()
        }
        .onChange(of: defaultCompressionFormat) { _ in
            saveSettings()
        }
    }

    // 保存设置
    func saveSettings() {
        UserDefaults.standard.set(defaultCompressionFormat, forKey: "DefaultCompressionFormat")
        UserDefaults.standard.set(sameUnZipFolder, forKey: "sameUnZipFolder")
        UserDefaults.standard.set(showDockIcon, forKey: "ShowDockIcon")
    }

    // 加载设置
    func loadSettings() {
        if let savedFormat = UserDefaults.standard.string(forKey: "DefaultCompressionFormat") {
            defaultCompressionFormat = savedFormat
        }
        sameUnZipFolder = UserDefaults.standard.bool(forKey: "sameUnZipFolder")
        showDockIcon = UserDefaults.standard.bool(forKey: "ShowDockIcon")
    }

    // 切换 Dock 图标的可见性
    func toggleDockIconVisibility(show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

#Preview {
    SettingsView()
}
