//
//  ContentView.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/27.
//

import KeyboardShortcuts
import SWCompression
import SwiftUI
import ZIPFoundation

struct ContentView: View {
    @State private var selectedFileURL: URL? = nil
    @State private var statusMessage: String = ""

    var body: some View {
        VStack {
            Text("Drag & Drop Files Here")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray, lineWidth: 2))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleFileDrop(providers: providers)
                }

            Text(statusMessage)
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
        .onAppear{
            setupGlobalShortcuts()
        }
    }

    // Handle file drop
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

    // Show save panel and process file
    func showSavePanelAndProcess() {
        guard let inputURL = selectedFileURL else {
            statusMessage = "No file selected"
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select output directory"
        panel.directoryURL = inputURL.deletingLastPathComponent() // 设置默认打开的目录为原文件所在目录

        if panel.runModal() == .OK {
            if let outputURL = panel.url {
                processFile(input: inputURL, output: outputURL)
            }
        }
    }

    // Process file (compress or decompress)
    func processFile(input: URL, output: URL) {
        let fileExtension = input.pathExtension.lowercased()

        switch fileExtension {
        case "zip":
            decompressZipFile(input: input, output: output)
        case "gz", "bz2", "xz", "tar":
            decompressWithSWCompression(input: input, output: output)
        default:
            compressToZip(input: input, output: output)
        }
    }

    // Decompress zip file using ZIPFoundation
    func decompressZipFile(input: URL, output: URL) {
        do {
            let destinationFolder = resolveUniqueURL(output.appendingPathComponent(input.deletingPathExtension().lastPathComponent))
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: input, to: destinationFolder)
            statusMessage = "Decompressed ZIP to \(destinationFolder.path)"
        } catch {
            statusMessage = "Decompression failed: \(error.localizedDescription)"
        }
    }

    // Decompress other formats using SWCompression
    func decompressWithSWCompression(input: URL, output: URL) {
        do {
            let destinationFolder = resolveUniqueURL(output.appendingPathComponent(input.deletingPathExtension().lastPathComponent))
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

            let data = try Data(contentsOf: input)
            let decompressedData: Data

            switch input.pathExtension {
            case "gz":
                decompressedData = try GzipArchive.unarchive(archive: data)
            case "bz2":
                decompressedData = try BZip2.decompress(data: data)
            case "xz":
                decompressedData = try XZArchive.unarchive(archive: data)
            case "tar":
                let entries = try TarContainer.open(container: data)
                for entry in entries {
                    if let entryData = entry.data {
                        let filePath = resolveUniqueURL(destinationFolder.appendingPathComponent(entry.info.name))
                        try entryData.write(to: filePath)
                    }
                }
                statusMessage = "Decompressed TAR to \(destinationFolder.path)"
                return
            default:
                throw NSError(domain: "UnsupportedFormat", code: 0, userInfo: nil)
            }

            let outputFile = destinationFolder.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
            try decompressedData.write(to: outputFile)
            statusMessage = "Decompressed \(input.pathExtension) to \(destinationFolder.path)"
        } catch {
            statusMessage = "Decompression failed: \(error.localizedDescription)"
        }
    }

    // Compress file to zip using ZIPFoundation
    func compressToZip(input: URL, output: URL) {
        do {
            let zipFileName = input.lastPathComponent + ".zip"
            let zipFileURL = resolveUniqueURL(output.appendingPathComponent(zipFileName))
            try FileManager.default.zipItem(at: input, to: zipFileURL)
            statusMessage = "Compressed to \(zipFileURL.path)"
        } catch {
            statusMessage = "Compression failed: \(error.localizedDescription)"
        }
    }

    // Resolve unique URL by adding a number if file/folder exists
    func resolveUniqueURL(_ url: URL) -> URL {
        var uniqueURL = url
        var counter = 1

        while FileManager.default.fileExists(atPath: uniqueURL.path) {
            let baseName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newName = "\(baseName) (\(counter))"
            uniqueURL = url.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(fileExtension)
            counter += 1
        }

        return uniqueURL
    }

    func getSelectedFileFromFinder() -> URL? {
        var selectedFileURL: URL?
        // AppleScript to check if Finder is running and get the selected file
          let script = """
          tell application "System Events"
              if not (exists process "Finder") then
                  tell application "Finder" to launch
              end if
          end tell
          delay 0.5
          tell application "Finder"
              set theSelection to selection as alias list
              if theSelection is not {} then
                  set theFile to item 1 of theSelection
                  POSIX path of theFile
              else
                  ""
              end if
          end tell
          """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                selectedFileURL = URL(fileURLWithPath: output)
            } else if let error = error {
                print("AppleScript Error: \(error)")
            }
        }

        return selectedFileURL
    }

    func setupGlobalShortcuts() {
        // 设置压缩快捷键
        KeyboardShortcuts.onKeyUp(for: .compress) {
            if let fileURL = self.getSelectedFileFromFinder() {
                DispatchQueue.main.async {
                    selectedFileURL = fileURL
                    showSavePanelAndProcess()
                }
            }
        }

        // 设置解压缩快捷键
        KeyboardShortcuts.onKeyUp(for: .decompress) {
            if let fileURL = self.getSelectedFileFromFinder() {
                DispatchQueue.main.async {
                    selectedFileURL = fileURL
                    showSavePanelAndProcess()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
