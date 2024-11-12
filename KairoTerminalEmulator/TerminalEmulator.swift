import Foundation
import SWCompression
import Yams

// MARK: - Config Model

struct Config: Decodable {
    let username: String
    let tarFilePath: String
    let logFilePath: String
}

func loadConfig(from url: URL) throws -> Config {
    let yamlString = try String(contentsOf: url, encoding: .utf8) // Updated to specify encoding
    let decoder = YAMLDecoder()
    let config = try decoder.decode(Config.self, from: yamlString)
    return config
}

// MARK: - Virtual File System

class VirtualFileSystem {
    var root: VirtualDirectory
    var currentDirectory: VirtualDirectory

    init(tarFileURL: URL) throws {
        self.root = VirtualDirectory(name: "/")
        self.currentDirectory = root
        try loadTarArchive(from: tarFileURL)
    }

    private func loadTarArchive(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let container = try TarContainer.open(container: data)
        for entry in container {
            let pathComponents = entry.info.name.split(separator: "/").map { String($0) }
            if entry.info.type == .directory {
                createDirectory(at: pathComponents)
            } else {
                if let fileData = entry.data {
                    createFile(at: pathComponents, content: fileData)
                } else {
                    print("Warning: No data for file at \(entry.info.name)")
                }
            }
        }
    }

    private func createDirectory(at pathComponents: [String]) {
        var currentDir = root
        for component in pathComponents {
            if let dir = currentDir.subdirectories.first(where: { $0.name == component }) {
                currentDir = dir
            } else {
                let newDir = VirtualDirectory(name: component)
                newDir.parent = currentDir
                currentDir.subdirectories.append(newDir)
                currentDir = newDir
            }
        }
    }

    private func createFile(at pathComponents: [String], content: Data) {
        var components = pathComponents
        guard let fileName = components.popLast() else { return }
        var currentDir = root
        for component in components {
            if let dir = currentDir.subdirectories.first(where: { $0.name == component }) {
                currentDir = dir
            } else {
                let newDir = VirtualDirectory(name: component)
                newDir.parent = currentDir
                currentDir.subdirectories.append(newDir)
                currentDir = newDir
            }
        }
        let file = VirtualFile(name: fileName, content: content)
        currentDir.files.append(file)
    }
}

class VirtualDirectory {
    let name: String
    var files: [VirtualFile] = []
    var subdirectories: [VirtualDirectory] = []
    weak var parent: VirtualDirectory?

    init(name: String) {
        self.name = name
    }
}

class VirtualFile {
    let name: String
    let content: Data

    init(name: String, content: Data) {
        self.name = name
        self.content = content
    }
}

// MARK: - Logger

class Logger {
    let logFileURL: URL
    let username: String

    init(logFileURL: URL, username: String) {
        self.logFileURL = logFileURL
        self.username = username
    }

    func log(action: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "\(timestamp),\(username),\(action)\n"
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}

// MARK: - Command Processor

class CommandProcessor {
    let fileSystem: VirtualFileSystem
    var currentDirectory: VirtualDirectory
    let logger: Logger

    init(fileSystem: VirtualFileSystem, logger: Logger) {
        self.fileSystem = fileSystem
        self.currentDirectory = fileSystem.root
        self.logger = logger
    }

    func execute(command: String) -> String {
        logger.log(action: command)
        let components = command.split(separator: " ")
        guard let baseCommand = components.first else {
            return ""
        }

        switch baseCommand {
        case "ls":
            return ls()
        case "cd":
            let path = components.count > 1 ? String(components[1]) : ""
            return cd(path: path)
        case "exit":
            exit(0)
        case "head":
            let filename = components.count > 1 ? String(components[1]) : ""
            return head(fileName: filename)
        case "cp":
            if components.count > 2 {
                let source = String(components[1])
                let destination = String(components[2])
                return cp(source: source, destination: destination)
            } else {
                return "cp: missing file operand"
            }
        case "du":
            return du()
        default:
            return "\(baseCommand): command not found"
        }
    }

    private func ls() -> String {
        var output = ""
        for dir in currentDirectory.subdirectories {
            output += dir.name + "\n"
        }
        for file in currentDirectory.files {
            output += file.name + "\n"
        }
        return output
    }

    private func cd(path: String) -> String {
        if path == ".." {
            if let parent = currentDirectory.parent {
                currentDirectory = parent
                return ""
            } else {
                return "Already at root directory."
            }
        } else if path == "/" {
            currentDirectory = fileSystem.root
            return ""
        } else if let dir = currentDirectory.subdirectories.first(where: { $0.name == path }) {
            currentDirectory = dir
            return ""
        } else {
            return "cd: no such file or directory: \(path)"
        }
    }

    private func head(fileName: String) -> String {
        if let file = currentDirectory.files.first(where: { $0.name == fileName }) {
            if let contentString = String(data: file.content, encoding: .utf8) {
                let lines = contentString.components(separatedBy: .newlines)
                let firstTenLines = lines.prefix(10).joined(separator: "\n")
                return firstTenLines
            } else {
                return "head: cannot display content."
            }
        } else {
            return "head: \(fileName): No such file"
        }
    }

    private func cp(source: String, destination: String) -> String {
        if let file = currentDirectory.files.first(where: { $0.name == source }) {
            // For simplicity, copying to current directory with new name
            let newFile = VirtualFile(name: destination, content: file.content)
            currentDirectory.files.append(newFile)
            return ""
        } else {
            return "cp: \(source): No such file"
        }
    }

    private func du() -> String {
        let size = calculateSize(directory: currentDirectory)
        return "Total size: \(size) bytes"
    }

    private func calculateSize(directory: VirtualDirectory) -> Int {
        var totalSize = 0
        for file in directory.files {
            totalSize += file.content.count
        }
        for dir in directory.subdirectories {
            totalSize += calculateSize(directory: dir)
        }
        return totalSize
    }
}
