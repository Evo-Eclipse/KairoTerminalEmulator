import SwiftUI

struct ContentView: View {
    @State private var command: String = ""
    @State private var output: String = ""
    @State private var showConfigUpload: Bool = true
    @State private var config: Config?
    @State private var commandProcessor: CommandProcessor?

    var body: some View {
        HStack {
            // Left Sidebar
            VStack(alignment: .leading) {
                if showConfigUpload {
                    ConfigUploadView(showConfigUpload: $showConfigUpload, config: $config, commandProcessor: $commandProcessor)
                } else {
                    CommandsListView(commandProcessor: commandProcessor)
                }
            }
            .frame(width: 300)
            .padding()
            .background(Color.black.opacity(0.9))

            // Right Terminal Window
            VStack {
                ScrollView {
                    Text(output)
                        .foregroundColor(.black)
                        .padding()
                }
                HStack {
                    Text("\(config?.username ?? "user")$ ")
                        .bold()
                    TextField("Enter command", text: $command, onCommit: {
                        if let processor = commandProcessor {
                            let result = processor.execute(command: command)
                            output += "\n\(config?.username ?? "user")$ \(command)\n\(result)"
                        } else {
                            output += "\nError: Configuration not loaded."
                        }
                        command = ""
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
            }
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ConfigUploadView: View {
    @Binding var showConfigUpload: Bool
    @Binding var config: Config?
    @Binding var commandProcessor: CommandProcessor?

    @State private var isTargeted: Bool = false

    var body: some View {
        VStack {
            Image(systemName: "tray.and.arrow.down.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding()
            Text("Перетащите файл конфигурации .yml для загрузки")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(isTargeted ? Color.blue.opacity(0.5) : Color.clear)
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        do {
                            let loadedConfig = try loadConfig(from: url)
                            DispatchQueue.main.async {
                                self.config = loadedConfig
                                do {
                                    let vfs = try VirtualFileSystem(tarFileURL: URL(fileURLWithPath: loadedConfig.tarFilePath))
                                    let logger = Logger(logFileURL: URL(fileURLWithPath: loadedConfig.logFilePath), username: loadedConfig.username)
                                    self.commandProcessor = CommandProcessor(fileSystem: vfs, logger: logger)
                                    self.showConfigUpload = false
                                } catch {
                                    print("Failed to initialize VirtualFileSystem: \(error)")
                                    // Could be implemented updating the UI to show an error message
                                }
                            }
                        } catch {
                            print("Failed to load config: \(error)")
                            // Could be implemented updating the UI to show an error message
                        }
                    }
                }
                return true
            }
            return false
        }
    }
}


struct CommandsListView: View {
    var commandProcessor: CommandProcessor?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            CommandButton(command: "ls", description: "Отображение списка файлов и директорий в текущей директории", commandProcessor: commandProcessor)
            CommandButton(command: "cd", description: "Изменение текущей директории", commandProcessor: commandProcessor)
            CommandButton(command: "exit", description: "Выход из терминала", commandProcessor: commandProcessor)
            CommandButton(command: "head", description: "Отображение первых строк файла", commandProcessor: commandProcessor)
            CommandButton(command: "cp", description: "Копирование файлов и директорий", commandProcessor: commandProcessor)
            CommandButton(command: "du", description: "Отображение использования диска", commandProcessor: commandProcessor)
        }
        .padding()
    }
}

struct CommandButton: View {
    let command: String
    let description: String
    var commandProcessor: CommandProcessor?

    var body: some View {
        Button(action: {
            // Could be implemented command execution if needed
        }) {
            VStack(alignment: .leading) {
                Text(command)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
