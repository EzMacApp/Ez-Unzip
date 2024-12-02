//
//  Helper.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/12/1.
//

import SWCompression
import SwiftUI
import UnrarKit

public enum TaskState {
    case Doing, Done(String), Error(String), Idle
}

class TaskHelper: ObservableObject {
    @Published var taskState = TaskState.Idle

    static let shard = TaskHelper()

    func compressToZip(input: URL, output: URL) {
        do {
            let zipFileName = input.lastPathComponent + ".zip"
            let zipFileURL = resolveUniqueURL(output.appendingPathComponent(zipFileName))
            try FileManager.default.zipItem(at: input, to: zipFileURL)
            taskState = TaskState.Done("Compressed to \(zipFileURL.path)")
        } catch {
            taskState = TaskState.Error("Compression failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 解压

    func decompressFile(input: URL, output: URL) {
        let fileExtension = input.pathExtension.lowercased()

        switch fileExtension {
        case "zip":
            decompressZipFile(input: input, output: output)
        case "gz", "bz2", "xz", "tar":
            decompressWithSWCompression(input: input, output: output)
        case "rar":
            decompressRarFile(input: input, output: output)
        default:
            taskState = TaskState.Error("Unsupported file format: \(fileExtension)")
            return
        }
        
        //清理__MACOSX
        deleteMacOSXFiles(in: output)

        // 检查解压后是否有嵌套的压缩文件
        recursivelyDecompressFiles(in: output.appendingPathComponent(input.deletingPathExtension().lastPathComponent))
    }

    func decompressZipFile(input: URL, output: URL) {
        do {
            let destinationFolder = output.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: input, to: destinationFolder, pathEncoding: .utf8)
            taskState = TaskState.Done("Decompressed ZIP to \(destinationFolder.path)")
        } catch {
            taskState = TaskState.Error("Decompression failed: \(error.localizedDescription)")
        }
    }

    func decompressRarFile(input: URL, output: URL) {
        do {
            let archive = try URKArchive(url: input)
            let destinationFolder = output.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            try archive.extractFiles(to: destinationFolder.path, overwrite: true)
            taskState = TaskState.Done("Successfully decompressed RAR to \(destinationFolder.path)")
        } catch {
            taskState = TaskState.Error("Decompression failed: \(error.localizedDescription)")
        }
    }

    func decompressWithSWCompression(input: URL, output: URL) {
        do {
            let destinationFolder = output.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

            let data = try Data(contentsOf: input)

            switch input.pathExtension {
            case "gz":
                let decompressedData = try GzipArchive.unarchive(archive: data)
                let outputFile = destinationFolder.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
                try decompressedData.write(to: outputFile)
            case "bz2":
                let decompressedData = try BZip2.decompress(data: data)
                let outputFile = destinationFolder.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
                try decompressedData.write(to: outputFile)
            case "xz":
                let decompressedData = try XZArchive.unarchive(archive: data)
                let outputFile = destinationFolder.appendingPathComponent(input.deletingPathExtension().lastPathComponent)
                try decompressedData.write(to: outputFile)
            case "tar":
                let entries = try TarContainer.open(container: data)
                for entry in entries {
                    if let entryData = entry.data {
                        let filePath = destinationFolder.appendingPathComponent(entry.info.name)
                        try entryData.write(to: filePath)
                    }
                }
            default:
                throw NSError(domain: "UnsupportedFormat", code: 0, userInfo: nil)
            }

            taskState = TaskState.Done("Decompressed \(input.pathExtension) to \(destinationFolder.path)")
        } catch {
            taskState = TaskState.Error("Decompression failed: \(error.localizedDescription)")
        }
    }

    func recursivelyDecompressFiles(in directory: URL) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

            for file in contents {
                let fileExtension = file.pathExtension.lowercased()

                if ["zip", "gz", "bz2", "xz", "tar", "rar"].contains(fileExtension) {
                    decompressFile(input: file, output: directory)
                }
            }
        } catch {
            taskState = TaskState.Error("Failed to process directory \(directory.path): \(error.localizedDescription)")
        }
    }

    // MARK: - 工具方法

    // 获取最近解压的目录
    func resolveLastDecompressionFolder(output: URL, input: URL) -> URL? {
        let lastPathComponent = input.deletingPathExtension().lastPathComponent
        let potentialFolder = output.appendingPathComponent(lastPathComponent)

        if FileManager.default.fileExists(atPath: potentialFolder.path) {
            return potentialFolder
        }

        return nil
    }

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
            }
        }
        return selectedFileURL
    }

    func deleteMacOSXFiles(in directory: URL) {
        let fileManager = FileManager.default

        do {
            // 获取目录中的所有内容
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

            for item in contents {
                if item.lastPathComponent == "__MACOSX" {
                    // 如果是 __MACOSX 文件或文件夹，直接删除
                    do {
                        try fileManager.removeItem(at: item)
                        print("Deleted: \(item.path)")
                    } catch {
                        print("Failed to delete: \(item.path). Error: \(error.localizedDescription)")
                    }
                } else {
                    // 如果是文件夹，递归检查
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue {
                        deleteMacOSXFiles(in: item)
                    }
                }
            }
        } catch {
            print("Failed to read contents of \(directory.path). Error: \(error.localizedDescription)")
        }
    }
}
