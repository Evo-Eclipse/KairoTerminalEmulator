import Testing
import Foundation
import SWCompression
@testable import KairoTerminalEmulator

struct KairoTerminalEmulatorTests {

    // MARK: - Tests for 'ls' Command

    @Test func testLSRootDirectory() async throws {
        // Set up the virtual file system
        var entries: [TarEntry] = []

        // Create directories
        let dir1EntryInfo = TarEntryInfo(name: "dir1/", type: .directory)
        entries.append(TarEntry(info: dir1EntryInfo, data: nil))

        let dir2EntryInfo = TarEntryInfo(name: "dir2/", type: .directory)
        entries.append(TarEntry(info: dir2EntryInfo, data: nil))

        // Create files
        let file1Content = Data("This is file1.".utf8)
        let file1EntryInfo = TarEntryInfo(name: "file1.txt", type: .regular)
        let file1Entry = TarEntry(info: file1EntryInfo, data: file1Content)
        entries.append(file1Entry)

        let file2Content = Data("This is file2.".utf8)
        let file2EntryInfo = TarEntryInfo(name: "file2.txt", type: .regular)
        let file2Entry = TarEntry(info: file2EntryInfo, data: file2Content)
        entries.append(file2Entry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write tarData to a temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_ls_root.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize the VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Set up the command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute the 'ls' command
        let output = commandProcessor.execute(command: "ls")

        // Expected output: list of files and directories
        let expectedItems = ["dir1", "dir2", "file1.txt", "file2.txt"]
        let outputItems = output.components(separatedBy: "\n").sorted()

        #expect(outputItems == expectedItems.sorted(), "Output items should match expected items")

        // Clean up temporary file
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    @Test func testLSSubdirectory() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create subdirectory 'dir1' with files
        let dir1EntryInfo = TarEntryInfo(name: "dir1/", type: .directory)
        entries.append(TarEntry(info: dir1EntryInfo, data: nil))

        let dir1File1Content = Data("This is dir1_file1.".utf8)
        let dir1File1EntryInfo = TarEntryInfo(name: "dir1/dir1_file1.txt", type: .regular)
        let dir1File1Entry = TarEntry(info: dir1File1EntryInfo, data: dir1File1Content)
        entries.append(dir1File1Entry)

        let dir1File2Content = Data("This is dir1_file2.".utf8)
        let dir1File2EntryInfo = TarEntryInfo(name: "dir1/dir1_file2.txt", type: .regular)
        let dir1File2Entry = TarEntry(info: dir1File2EntryInfo, data: dir1File2Content)
        entries.append(dir1File2Entry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write tarData to a temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_ls_subdir.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize the VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Set up the command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Change directory to 'dir1'
        _ = commandProcessor.execute(command: "cd dir1")

        // Execute the 'ls' command
        let output = commandProcessor.execute(command: "ls")

        // Expected output: list of files in dir1
        let expectedItems = ["dir1_file1.txt", "dir1_file2.txt"]
        let outputItems = output.components(separatedBy: "\n").sorted()

        #expect(outputItems == expectedItems.sorted(), "Output items should match expected items")

        // Clean up temporary file
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    // MARK: - Tests for 'cd' Command

    @Test func testCDValidDirectory() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create subdirectory 'dir1'
        let dir1EntryInfo = TarEntryInfo(name: "dir1/", type: .directory)
        entries.append(TarEntry(info: dir1EntryInfo, data: nil))

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write to a temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_cd_valid.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'cd dir1'
        let output = commandProcessor.execute(command: "cd dir1")

        #expect(output == "", "cd to existing directory should produce no output")
        #expect(commandProcessor.currentDirectory.name == "dir1", "Should be in 'dir1' directory")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    @Test func testCDInvalidDirectory() async throws {
        // Empty tar entries
        let tarData = TarContainer.create(from: [])

        // Write to a temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_cd_invalid.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'cd nonExistentDir'
        let output = commandProcessor.execute(command: "cd nonExistentDir")

        let expectedOutput = "cd: no such file or directory: nonExistentDir"
        #expect(output == expectedOutput, "Should receive an error for non-existent directory")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    // MARK: - Tests for 'head' Command

    @Test func testHeadExistingFile() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create a file with more than 10 lines
        let contentLines = (1...15).map { "Line \($0)" }
        let fileContent = contentLines.joined(separator: "\n")
        let fileData = Data(fileContent.utf8)

        let fileEntryInfo = TarEntryInfo(name: "testfile.txt", type: .regular)
        let fileEntry = TarEntry(info: fileEntryInfo, data: fileData)
        entries.append(fileEntry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_head_existing.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'head testfile.txt'
        let output = commandProcessor.execute(command: "head testfile.txt")

        let expectedOutput = contentLines.prefix(10).joined(separator: "\n")
        #expect(output == expectedOutput, "Output should be the first 10 lines of the file")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    @Test func testHeadNonexistentFile() async throws {
        // Empty tar entries
        let tarData = TarContainer.create(from: [])

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_head_nonexistent.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'head nonexistent.txt'
        let output = commandProcessor.execute(command: "head nonexistent.txt")

        let expectedOutput = "head: nonexistent.txt: No such file"
        #expect(output == expectedOutput, "Should receive an error for non-existent file")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    // MARK: - Tests for 'cp' Command

    @Test func testCPExistingFile() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create a file
        let fileContent = Data("This is a test file.".utf8)
        let fileEntryInfo = TarEntryInfo(name: "source.txt", type: .regular)
        let fileEntry = TarEntry(info: fileEntryInfo, data: fileContent)
        entries.append(fileEntry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_cp_existing.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'cp source.txt dest.txt'
        let output = commandProcessor.execute(command: "cp source.txt dest.txt")

        #expect(output == "", "cp should produce no output on success")
        #expect(commandProcessor.currentDirectory.files.contains(where: { $0.name == "dest.txt" }), "'dest.txt' should exist")

        // Verify content
        if let destFile = commandProcessor.currentDirectory.files.first(where: { $0.name == "dest.txt" }) {
            #expect(destFile.content == fileContent, "Contents should match")
        }

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    @Test func testCPNonexistentFile() async throws {
        // Empty tar entries
        let tarData = TarContainer.create(from: [])

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_cp_nonexistent.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'cp nonexistent.txt dest.txt'
        let output = commandProcessor.execute(command: "cp nonexistent.txt dest.txt")

        let expectedOutput = "cp: nonexistent.txt: No such file"
        #expect(output == expectedOutput, "Should receive an error for non-existent source file")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    // MARK: - Tests for 'du' Command

    @Test func testDURootDirectory() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create files
        let file1Content = Data("File one content".utf8)
        let file1EntryInfo = TarEntryInfo(name: "file1.txt", type: .regular)
        let file1Entry = TarEntry(info: file1EntryInfo, data: file1Content)
        entries.append(file1Entry)

        let file2Content = Data("File two content".utf8)
        let file2EntryInfo = TarEntryInfo(name: "file2.txt", type: .regular)
        let file2Entry = TarEntry(info: file2EntryInfo, data: file2Content)
        entries.append(file2Entry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_du_root.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Execute 'du'
        let output = commandProcessor.execute(command: "du")

        let totalSize = file1Content.count + file2Content.count
        let expectedOutput = "Total size: \(totalSize) bytes"

        #expect(output == expectedOutput, "Should report correct total size")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }

    @Test func testDUSubdirectory() async throws {
        // Create tar entries
        var entries: [TarEntry] = []

        // Create subdirectory with files
        let dirEntryInfo = TarEntryInfo(name: "dir/", type: .directory)
        entries.append(TarEntry(info: dirEntryInfo, data: nil))

        let fileContent = Data("Subdirectory file content".utf8)
        let fileEntryInfo = TarEntryInfo(name: "dir/file.txt", type: .regular)
        let fileEntry = TarEntry(info: fileEntryInfo, data: fileContent)
        entries.append(fileEntry)

        // Create tar container
        let tarData = TarContainer.create(from: entries)

        // Write to temporary file
        let tempTarFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_du_subdir.tar")
        try tarData.write(to: tempTarFileURL)

        // Initialize VirtualFileSystem
        let vfs = try VirtualFileSystem(tarFileURL: tempTarFileURL)

        // Command processor
        let logger = Logger(logFileURL: URL(fileURLWithPath: "/dev/null"), username: "testuser")
        let commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)

        // Change directory
        _ = commandProcessor.execute(command: "cd dir")

        // Execute 'du'
        let output = commandProcessor.execute(command: "du")

        let totalSize = fileContent.count
        let expectedOutput = "Total size: \(totalSize) bytes"

        #expect(output == expectedOutput, "Should report correct total size in subdirectory")

        // Clean up
        try FileManager.default.removeItem(at: tempTarFileURL)
    }
}
