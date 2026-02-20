import SwiftUI
import NimbleViews

// MARK: - Advanced File Tools Terminal View
struct FileToolsTerminalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: TerminalViewModel
    @FocusState private var isInputFocused: Bool

    init(currentDirectory: URL) {
        _viewModel = StateObject(wrappedValue: TerminalViewModel(currentDirectory: currentDirectory))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Terminal Output Area
                outputArea

                // Input Area
                inputArea
            }
            .navigationTitle(.localized("Terminal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    terminalMenu
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    // Welcome message
                    Text("Portal Terminal v2.0")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    ForEach(viewModel.history) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("\(viewModel.currentPathName) $")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.green)

                                Text(item.command)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                            }

                            if !item.output.isEmpty {
                                Text(item.output)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(item.isError ? .red : .secondary)
                                    .padding(.leading, 12)
                                    .textSelection(.enabled)
                            }
                        }
                        .id(item.id)
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(colorScheme == .dark ? 0.95 : 0.9))
            .onChange(of: viewModel.history.count) { _ in
                if let last = viewModel.history.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Text(">")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)

                TextField(.localized("Enter Command"), text: $viewModel.currentInput)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.execute()
                    }

                if !viewModel.currentInput.isEmpty {
                    Button {
                        viewModel.execute()
                    } label: {
                        Image(systemName: "return")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color.clear)

            // Command History / Suggestions bar
            if !viewModel.commandHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.commandHistory.reversed().prefix(10), id: \.self) { cmd in
                            Button {
                                viewModel.currentInput = cmd
                            } label: {
                                Text(cmd)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color.primary.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.clear)
            }
        }
    }

    private var terminalMenu: some View {
        Menu {
            Section("File Operations") {
                Button("ls - List Files") { viewModel.currentInput = "ls" }
                Button("pwd - Print Directory") { viewModel.currentInput = "pwd" }
                Button("mkdir - Create Folder") { viewModel.currentInput = "mkdir " }
                Button("touch - Create File") { viewModel.currentInput = "touch " }
            }

            Section("Manipulation") {
                Button("cp - Copy") { viewModel.currentInput = "cp " }
                Button("mv - Move/Rename") { viewModel.currentInput = "mv " }
                Button("rm - Remove") { viewModel.currentInput = "rm " }
                Button("cat - Read File") { viewModel.currentInput = "cat " }
            }

            Section("Terminal") {
                Button("clear - Clear Output") { viewModel.executeCommand("clear") }
                Button("help - Show Help") { viewModel.executeCommand("help") }
            }
        } label: {
            Image(systemName: "terminal.fill")
        }
    }
}

// MARK: - Terminal View Model
class TerminalViewModel: ObservableObject {
    @Published var currentInput = ""
    @Published var history: [TerminalEntry] = []
    @Published var commandHistory: [String] = []
    @Published var currentDirectory: URL

    struct TerminalEntry: Identifiable {
        let id = UUID()
        let command: String
        let output: String
        let isError: Bool
    }

    var currentPathName: String {
        currentDirectory.lastPathComponent
    }

    init(currentDirectory: URL) {
        self.currentDirectory = currentDirectory
    }

    func execute() {
        let cmd = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }

        executeCommand(cmd)
        currentInput = ""
    }

    func executeCommand(_ command: String) {
        if command == "clear" {
            history.removeAll()
            return
        }

        if !commandHistory.contains(command) {
            commandHistory.append(command)
        }

        let parts = command.split(separator: " ").map(String.init)
        let baseCmd = parts.first?.lowercased() ?? ""
        let args = parts.dropFirst()

        var output = ""
        var isError = false

        switch baseCmd {
        case "ls":
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: [.isDirectoryKey])
                output = contents.map { url in
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDir ? "\(url.lastPathComponent)/" : url.lastPathComponent
                }.sorted().joined(separator: "\n")
            } catch {
                output = error.localizedDescription
                isError = true
            }

        case "pwd":
            output = currentDirectory.path

        case "cd":
            if let path = args.first {
                if path == ".." {
                    currentDirectory = currentDirectory.deletingLastPathComponent()
                    output = "Moved to: \(currentDirectory.lastPathComponent)"
                } else {
                    let newDir = currentDirectory.appendingPathComponent(path)
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: newDir.path, isDirectory: &isDir), isDir.boolValue {
                        currentDirectory = newDir
                        output = "Moved to: \(path)"
                    } else {
                        output = "cd: \(path): No such directory"
                        isError = true
                    }
                }
            }

        case "cat":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    output = content
                } else {
                    output = "cat: \(path): No such file or unable to read"
                    isError = true
                }
            }

        case "mkdir":
            if let path = args.first {
                let dirURL = currentDirectory.appendingPathComponent(path)
                do {
                    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
                    output = "Created directory: \(path)"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            }

        case "rm":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    output = "Removed: \(path)"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            }

        case "touch":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                if FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
                    output = "Created file: \(path)"
                } else {
                    output = "touch: \(path): Failed to create"
                    isError = true
                }
            }

        case "cp":
            if args.count >= 2 {
                let src = currentDirectory.appendingPathComponent(args[0])
                let dst = currentDirectory.appendingPathComponent(args[1])
                do {
                    try FileManager.default.copyItem(at: src, to: dst)
                    output = "Copied \(args[0]) to \(args[1])"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            } else {
                output = "Usage: cp <source> <destination>"
                isError = true
            }

        case "mv":
            if args.count >= 2 {
                let src = currentDirectory.appendingPathComponent(args[0])
                let dst = currentDirectory.appendingPathComponent(args[1])
                do {
                    try FileManager.default.moveItem(at: src, to: dst)
                    output = "Moved/Renamed \(args[0]) to \(args[1])"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            } else {
                output = "Usage: mv <source> <destination>"
                isError = true
            }

        case "help":
            output = """
            Available commands:
            ls      - List contents
            pwd     - Print working directory
            cd      - Change directory
            cat     - Read file content
            mkdir   - Create directory
            rm      - Remove file/directory
            touch   - Create empty file
            cp      - Copy item
            mv      - Move/Rename item
            clear   - Clear terminal
            help    - Show this help
            """

        default:
            output = "sh: command not found: \(baseCmd)"
            isError = true
        }

        history.append(TerminalEntry(command: command, output: output, isError: isError))
    }
}
