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
}
