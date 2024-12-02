//
//  Constants.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/28.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let compress = Self("ez-compress", default: .init(.z, modifiers: [.command, .option]))
    static let decompress = Self("ez-decompress", default: .init(.u, modifiers: [.command, .option]))
    static let openMain = Self("ez-open-main", default: .init(.m, modifiers: [.command, .control]))
    static let openSetting = Self("ez-open-setting", default: .init(.s, modifiers: [.command, .control]))
    static let quit = Self("ez-quit", default: .init(.q, modifiers: [.command]))
}
