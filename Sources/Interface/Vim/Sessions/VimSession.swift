/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSession.swift (c) 2025
Desc: VimSession implementation using vim subprocess for automation
Created:  2025-08-22T03:16:23.191Z
*/

import Foundation
import Darwin

class VimSession: VimSessionProtocol {
    private let vimPath: String
    private let gvimPath: String?
    private let vimrcPath: String
    private var isSessionRunning = false
    private var tempDirectory: URL?
    private var serverName: String?
    private var serverProcess: Process?
    private var useClientServer: Bool = false
    
    // Current session state
    private var currentBuffer: [String] = [""]
    private var currentCursor: (row: Int, col: Int) = (0, 0)
    private var currentMode: String = "n"
    
    init(vimPath: String? = nil) {
        // Find vim executable
        if let customPath = vimPath {
            self.vimPath = customPath
            self.gvimPath = nil
        } else {
            // Prefer MacVim for better client-server support
            let possibleVimPaths = [
                "/opt/homebrew/bin/vim",    // MacVim via Homebrew
                "/usr/local/bin/vim",       // MacVim via manual install
                "/usr/bin/vim"              // System vim
            ]
            
            let possibleGvimPaths = [
                "/opt/homebrew/bin/gvim",   // MacVim GUI via Homebrew
                "/usr/local/bin/gvim",      // MacVim GUI via manual install
                "/Applications/MacVim.app/Contents/bin/gvim"  // MacVim app
            ]
            
            self.vimPath = possibleVimPaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/vim"
            self.gvimPath = possibleGvimPaths.first { FileManager.default.fileExists(atPath: $0) }
        }
        
        // Get the path to vimgolf.vimrc 
        let bundlePath = Bundle.main.bundlePath
        if !bundlePath.isEmpty {
            self.vimrcPath = bundlePath + "/../../Sources/Interface/Golf/vimgolf.vimrc"
        } else {
            // Fallback for test environment
            self.vimrcPath = "Sources/Interface/Golf/vimgolf.vimrc"
        }
    }
    
    func start() throws {
        guard !isSessionRunning else { return }
        
        // Create temporary directory for session files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VimSession_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        self.tempDirectory = tempDir
        
        // Try to use client-server mode if MacVim GUI is available
        if let gvimPath = gvimPath {
            do {
                try startMacVimServer(gvimPath: gvimPath)
                useClientServer = true
            } catch {
                // Fall back to script mode if server setup fails
                print("Warning: Could not start MacVim server, falling back to script mode: \(error)")
                useClientServer = false
            }
        } else {
            useClientServer = false
        }
        
        // Initialize session state
        currentBuffer = [""]
        currentCursor = (0, 0)
        currentMode = "n"
        isSessionRunning = true
    }
    

    
    func stop() {
        guard isSessionRunning else { return }
        
        // Stop the MacVim server if running
        if useClientServer, let serverName = serverName {
            try? sendServerCommand(":qall!")
            serverProcess?.terminate()
            serverProcess = nil
        }
        
        // Clean up temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
            tempDirectory = nil
        }
        
        useClientServer = false
        serverName = nil
        isSessionRunning = false
    }
    
    func isRunning() -> Bool {
        return isSessionRunning
    }
    
    func sendInput(_ input: String) throws {
        guard isSessionRunning else {
            throw VimSessionError.notRunning
        }
        
        if useClientServer {
            // Use MacVim client-server for real mode querying
            var commandToSend = input
            
            // Auto-complete colon commands that don't end with CR
            if input.hasPrefix(":") && !input.contains("<CR>") && !input.contains("\\<CR>") && !input.hasSuffix("\n") && !input.hasSuffix("\r") {
                commandToSend = input + "<CR>"
            }
            
            try sendServerCommand(commandToSend)
            
            // Small delay to let command complete
            Thread.sleep(forTimeInterval: 0.05)
            
            // Query the real mode from vim
            let realMode = try queryServerMode()
            currentMode = realMode
            
            // Update cursor position
            let cursorInfo = try queryServerCursor()
            currentCursor = cursorInfo
            
            // Update buffer content (simplified for now)
            // In a full implementation, you'd query buffer content too
            
        } else {
            // Fall back to script-based execution
            guard let tempDir = tempDirectory else {
                throw VimSessionError.notRunning
            }
            
            let result = try executeVimCommand(input, tempDir: tempDir)
            currentBuffer = result.finalText.isEmpty ? [""] : result.finalText.components(separatedBy: "\n")
            currentCursor = result.cursorPosition
            currentMode = result.mode
        }
    }
    
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String] {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
        // Only support buffer 1 (the current buffer) and 0 (current window buffer)
        guard buffer == 0 || buffer == 1 else {
            throw VimSessionError.invalidResponse("Invalid buffer number: \(buffer)")
        }
        
        let actualEnd = end == -1 ? currentBuffer.count : min(end, currentBuffer.count)
        let actualStart = max(0, start)
        
        guard actualStart <= actualEnd && actualStart < currentBuffer.count else {
            return []
        }
        
        return Array(currentBuffer[actualStart..<min(actualEnd, currentBuffer.count)])
    }
    
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
        // Only support buffer 1 (the current buffer) and 0 (current window buffer)
        guard buffer == 0 || buffer == 1 else {
            throw VimSessionError.invalidResponse("Invalid buffer number: \(buffer)")
        }
        
        let actualStart = max(0, start)
        let actualEnd = end == -1 ? currentBuffer.count : min(end, currentBuffer.count)
        
        // Replace the range with new lines
        var newBuffer = currentBuffer
        
        // Remove old lines
        if actualEnd > actualStart && actualStart < newBuffer.count {
            newBuffer.removeSubrange(actualStart..<min(actualEnd, newBuffer.count))
        }
        
        // Insert new lines
        for (index, line) in lines.enumerated() {
            if actualStart + index <= newBuffer.count {
                newBuffer.insert(line, at: actualStart + index)
            } else {
                newBuffer.append(line)
            }
        }
        
        // Ensure at least one line
        if newBuffer.isEmpty {
            newBuffer = [""]
        }
        
        currentBuffer = newBuffer
        
        // Adjust cursor if needed
        if currentCursor.row >= currentBuffer.count {
            currentCursor.row = max(0, currentBuffer.count - 1)
        }
        if currentCursor.col >= currentBuffer[currentCursor.row].count {
            currentCursor.col = max(0, currentBuffer[currentCursor.row].count - 1)
        }
    }
    
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int) {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
        // Only support window 0 (current window)
        guard window == 0 else {
            throw VimSessionError.invalidResponse("Invalid window number: \(window)")
        }
        
        return currentCursor
    }
    
    func setCursorPosition(window: Int, row: Int, col: Int) throws {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
        // Only support window 0 (current window)
        guard window == 0 else {
            throw VimSessionError.invalidResponse("Invalid window number: \(window)")
        }
        
        let actualRow = max(0, min(row, currentBuffer.count - 1))
        let actualCol = max(0, min(col, currentBuffer[actualRow].count))
        
        currentCursor = (row: actualRow, col: actualCol)
    }
    
    func getMode() throws -> (mode: String, blocking: Bool) {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        return (mode: currentMode, blocking: false)
    }
    
    // MARK: - MacVim Client-Server Methods
    
    private func startMacVimServer(gvimPath: String) throws {
        let uniqueServerName = "VIMSESSION_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))"
        
        // Create a temporary file for the server
        guard let tempDir = tempDirectory else {
            throw VimSessionError.notRunning
        }
        let tempFile = tempDir.appendingPathComponent("server_buffer.txt")
        try "".write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Start MacVim GUI as server
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
        process.arguments = [
            "-u", vimrcPath,
            "--servername", uniqueServerName,
            "--remote-tab-silent", tempFile.path
        ]
        
        // Redirect output to avoid GUI dialogs
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        try process.run()
        self.serverProcess = process
        self.serverName = uniqueServerName
        
        // Wait for server to be ready
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            Thread.sleep(forTimeInterval: 0.2)
            attempts += 1
            
            do {
                let servers = try listVimServers()
                if servers.contains(uniqueServerName) {
                    // Server is ready
                    return
                }
            } catch {
                if attempts == maxAttempts {
                    throw VimSessionError.startupFailed(error)
                }
            }
        }
        
        throw VimSessionError.startupFailed(NSError(domain: "VimSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "MacVim server failed to start after \(maxAttempts) attempts"]))
    }
    
    private func listVimServers() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = ["--serverlist"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus != 0 {
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw VimSessionError.communicationFailed("Failed to list servers: \(error)")
        }
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    private func sendServerCommand(_ command: String) throws {
        guard let serverName = serverName else {
            throw VimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-send", command
        ]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw VimSessionError.communicationFailed("Server send failed: \(error)")
        }
    }
    
    private func queryServerMode() throws -> String {
        guard let serverName = serverName else {
            throw VimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-expr", "mode()"
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw VimSessionError.communicationFailed("Mode query failed: \(error)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "n"
    }
    
    private func queryServerCursor() throws -> (row: Int, col: Int) {
        guard let serverName = serverName else {
            throw VimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-expr", "string(getpos('.'))"
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw VimSessionError.communicationFailed("Cursor query failed: \(error)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Parse cursor position from getpos('.') result: ['0', 'line', 'col', '0']
        let components = result.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").components(separatedBy: ",")
        
        if components.count >= 4 {
            let row = max(0, (Int(components[1].trimmingCharacters(in: .whitespaces)) ?? 1) - 1)
            let col = max(0, (Int(components[2].trimmingCharacters(in: .whitespaces)) ?? 1) - 1)
            return (row: row, col: col)
        }
        
        return (row: 0, col: 0)
    }
    
    // MARK: - Private Helper Methods
    

    
    private struct VimExecutionResult {
        let finalText: String
        let cursorPosition: (row: Int, col: Int)
        let mode: String
        let success: Bool
    }
    
    private func executeVimCommand(_ command: String, tempDir: URL) throws -> VimExecutionResult {
        // Create input file with current buffer content
        let inputFile = tempDir.appendingPathComponent("input.txt")
        let outputFile = tempDir.appendingPathComponent("output.txt")
        let cursorFile = tempDir.appendingPathComponent("cursor.txt")
        
        // Write current buffer to input file
        let inputText = currentBuffer.joined(separator: "\n")
        try inputText.write(to: inputFile, atomically: true, encoding: .utf8)
        
        // Use vim script execution for reliable behavior
        return try executeVimWithScript(command: command, inputFile: inputFile, outputFile: outputFile, cursorFile: cursorFile)
    }
    

    
    private func executeVimWithScript(command: String, inputFile: URL, outputFile: URL, cursorFile: URL) throws -> VimExecutionResult {
        let escapedCommand = escapeVimInput(command)
        
        // Smart mode tracking: analyze the command sequence to determine the final mode
        let finalMode = analyzeCommandForFinalMode(command: command, currentMode: currentMode)
        
        // Execute vim in Ex mode - this approach is reliable and fast
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "-u", vimrcPath,
            "-n", "-e", "-s",  // No swap, Ex mode, silent
            "-c", "call cursor(\(currentCursor.row + 1), \(currentCursor.col + 1))",
            "-c", "execute \"normal! \(escapedCommand)\"",
            "-c", "let cursor_pos = getpos('.')",
            "-c", "call writefile([cursor_pos[1] . ',' . cursor_pos[2] . ',' . '\(finalMode)'], '\(cursorFile.path)')",
            "-c", "write! \(outputFile.path)",
            "-c", "qall!",
            inputFile.path
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Read the results
            let finalText = try String(contentsOf: outputFile, encoding: .utf8)
            let cursorData = try String(contentsOf: cursorFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            let cursorComponents = cursorData.components(separatedBy: ",")
            
            var cursorRow = 0
            var cursorCol = 0
            var mode = "n"
            
            if cursorComponents.count >= 3 {
                cursorRow = max(0, (Int(cursorComponents[0]) ?? 1) - 1)
                cursorCol = max(0, (Int(cursorComponents[1]) ?? 1) - 1)
                mode = cursorComponents[2]
            }
            
            return VimExecutionResult(
                finalText: finalText.hasSuffix("\n") ? String(finalText.dropLast()) : finalText,
                cursorPosition: (row: cursorRow, col: cursorCol),
                mode: mode,
                success: process.terminationStatus == 0
            )
            
        } catch {
            throw VimSessionError.communicationFailed("Failed to execute vim command: \(error)")
        }
    }
    
    private func executeVimWithPTY(command: String, inputFile: URL, outputFile: URL, cursorFile: URL) throws -> VimExecutionResult {
        let escapedCommand = escapeVimInput(command)
        
        // Create a pseudo-terminal
        var masterFd: Int32 = 0
        var slaveFd: Int32 = 0
        
        guard openpty(&masterFd, &slaveFd, nil, nil, nil) == 0 else {
            throw VimSessionError.communicationFailed("Failed to create pseudo-terminal")
        }
        
        defer {
            close(masterFd)
            close(slaveFd)
        }
        
        // Create vim process with PTY for true interactive behavior
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "-u", vimrcPath,
            "-n",  // No swap file
            inputFile.path
        ]
        
        // Redirect process to use the slave side of PTY
        let slaveFdHandle = FileHandle(fileDescriptor: slaveFd, closeOnDealloc: false)
        process.standardInput = slaveFdHandle
        process.standardOutput = slaveFdHandle
        process.standardError = slaveFdHandle
        
        do {
            try process.run()
            
            // Use the master side to communicate with vim
            let masterFdHandle = FileHandle(fileDescriptor: masterFd, closeOnDealloc: false)
            
            // Send vim commands through PTY with proper command structure
            let commands = [
                ":call cursor(\(currentCursor.row + 1), \(currentCursor.col + 1))\r",
                "\(escapedCommand)",
                ":let current_mode = mode()\r",
                ":let cursor_pos = getpos('.')\r",
                ":call writefile([cursor_pos[1] . ',' . cursor_pos[2] . ',' . current_mode], '\(cursorFile.path)')\r",
                ":write! \(outputFile.path)\r",
                ":qall!\r"
            ]
            
            for command in commands {
                masterFdHandle.write(command.data(using: .utf8)!)
                Thread.sleep(forTimeInterval: 0.1) // Small delay between commands
            }
            
            // Give vim time to process and exit
            Thread.sleep(forTimeInterval: 0.5)
            
            process.waitUntilExit()
            
            // Read the results
            let finalText = try String(contentsOf: outputFile, encoding: .utf8)
            let cursorData = try String(contentsOf: cursorFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            let cursorComponents = cursorData.components(separatedBy: ",")
            
            var cursorRow = 0
            var cursorCol = 0
            var mode = "n"
            
            if cursorComponents.count >= 3 {
                cursorRow = max(0, (Int(cursorComponents[0]) ?? 1) - 1)
                cursorCol = max(0, (Int(cursorComponents[1]) ?? 1) - 1)
                mode = cursorComponents[2]
            }
            
            return VimExecutionResult(
                finalText: finalText.hasSuffix("\n") ? String(finalText.dropLast()) : finalText,
                cursorPosition: (row: cursorRow, col: cursorCol),
                mode: mode,
                success: process.terminationStatus == 0
            )
            
        } catch {
            throw VimSessionError.communicationFailed("Failed to execute vim command with PTY: \(error)")
        }
    }
    

    
    private func analyzeCommandForFinalMode(command: String, currentMode: String) -> String {
        // This method analyzes a vim command sequence to predict the final mode
        // It handles complex sequences and mode transitions properly
        
        var mode = currentMode
        var i = command.startIndex
        
        while i < command.endIndex {
            let char = command[i]
            
            switch mode {
            case "n": // Normal mode
                switch char {
                case "i":
                    // Check if it's just 'i' or 'i' followed by text
                    mode = "i"
                case "a":
                    mode = "i"
                case "o", "O":
                    mode = "i"
                case "A":
                    mode = "i"
                case "I":
                    mode = "i"
                case "v":
                    mode = "v"
                case "V":
                    mode = "V"
                case "R":
                    mode = "R"
                case ":":
                    // Command mode - scan to end of line, CR, or <CR> pattern
                    while i < command.endIndex {
                        let remaining = String(command[i...])
                        if remaining.hasPrefix("<CR>") || remaining.hasPrefix("\\<CR>") {
                            // Found command completion - return to normal mode
                            mode = "n"
                            if remaining.hasPrefix("<CR>") {
                                i = command.index(i, offsetBy: 3)  // Skip <CR>
                            } else {
                                i = command.index(i, offsetBy: 5)  // Skip \<CR>
                            }
                            break
                        } else if command[i] == "\n" || command[i] == "\r" {
                            // Line ending completes command
                            mode = "n"
                            break
                        } else {
                            i = command.index(after: i)
                        }
                    }
                    continue
                default:
                    // Most normal mode commands keep us in normal mode
                    break
                }
                
            case "i": // Insert mode
                // Check for escape sequences
                if char == "\u{1b}" || (char == "\\" && i < command.index(before: command.endIndex) && command[command.index(after: i)] == "<") {
                    // Look for <Esc> pattern
                    let remaining = String(command[i...])
                    if remaining.hasPrefix("\\<Esc>") || remaining.hasPrefix("\u{1b}") {
                        mode = "n"
                        // Skip the escape sequence
                        if remaining.hasPrefix("\\<Esc>") {
                            i = command.index(i, offsetBy: 5) // Skip \<Esc>
                            continue
                        }
                    }
                }
                // In insert mode, most characters just insert text
                
            case "v", "V": // Visual modes
                if char == "\u{1b}" || (char == "\\" && i < command.index(before: command.endIndex) && command[command.index(after: i)] == "<") {
                    let remaining = String(command[i...])
                    if remaining.hasPrefix("\\<Esc>") || remaining.hasPrefix("\u{1b}") {
                        mode = "n"
                        if remaining.hasPrefix("\\<Esc>") {
                            i = command.index(i, offsetBy: 5)
                            continue
                        }
                    }
                }
                
            case "R": // Replace mode
                if char == "\u{1b}" || (char == "\\" && i < command.index(before: command.endIndex) && command[command.index(after: i)] == "<") {
                    let remaining = String(command[i...])
                    if remaining.hasPrefix("\\<Esc>") || remaining.hasPrefix("\u{1b}") {
                        mode = "n"
                        if remaining.hasPrefix("\\<Esc>") {
                            i = command.index(i, offsetBy: 5)
                            continue
                        }
                    }
                }
                
            default:
                break
            }
            
            i = command.index(after: i)
        }
        
        return mode
    }
    
    private func escapeVimInput(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "<Esc>", with: "\\<Esc>")
            .replacingOccurrences(of: "<CR>", with: "\\<CR>")
            .replacingOccurrences(of: "<Tab>", with: "\\<Tab>")
            .replacingOccurrences(of: "<BS>", with: "\\<BS>")
            .replacingOccurrences(of: "\u{1b}", with: "\\<Esc>")  // Escape character
    }
}

enum VimSessionError: Error {
    case startupFailed(Error)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
}
