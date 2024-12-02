//
//  ContentView.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/27.
//

import KeyboardShortcuts
import LaunchAtLogin
import SWCompression
import SwiftUI
import UnrarKit
import ZIPFoundation

struct ContentView: View {
    @State private var selectedFileURL: URL? = nil
//    @State public var statusMessage: String = ""
    @State private var taskHelper = TaskHelper.shard
    @State private var isProcessing: Bool = false // 添加任务状态

    var body: some View {
        VStack {
            if isProcessing {
                ProgressView("Processing...")
                    .padding()
            } else {
                Text("Drag & Drop Files Here")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray, lineWidth: 2))
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleFileDrop(providers: providers)
                    }
            }
        }
        .padding()
    }

    func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    selectedFileURL = fileURL
                    showSavePanelAndProcess()
                }
            }
        }
        return true
    }

    func showSavePanelAndProcess() {
        guard let inputURL = selectedFileURL else {
            var statusMessage = "No file selected"
            return
        }

        // 默认保存路径为输入文件所在目录
        let outputURL = inputURL.deletingLastPathComponent()

        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            taskHelper.decompressFile(input: inputURL, output: outputURL)
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

#Preview {
    ContentView()
}
