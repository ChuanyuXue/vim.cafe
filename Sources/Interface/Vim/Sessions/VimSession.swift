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
    private let vimrcPath: String
    private var isSessionRunning = false
    private var tempDirectory: URL?
    
    // Current session state
    private var currentBuffer: [String] = [""]
    private var currentCursor: (row: Int, col: Int) = (0, 0)
    private var currentMode: String = "n"
    
    init(vimPath: String? = nil) {
        // Find vim executable
        if let customPath = vimPath {
            self.vimPath = customPath
        } else {
            // Try common vim locations - prefer versions that likely support client-server
            let possiblePaths = [
                "/opt/homebrew/bin/vim",
                "/usr/local/bin/vim", 
                "/usr/bin/vim"
            ]
            
            self.vimPath = possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/vim"
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
        
        // Initialize session state
        currentBuffer = [""]
        currentCursor = (0, 0)
        currentMode = "n"
        isSessionRunning = true
    }
    

    
    func stop() {
        guard isSessionRunning else { return }
        
        // Clean up temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
            tempDirectory = nil
        }
        
        isSessionRunning = false
    }
    
    func isRunning() -> Bool {
        return isSessionRunning
    }
    
    func sendInput(_ input: String) throws {
        guard let tempDir = tempDirectory else {
            throw VimSessionError.notRunning
        }
        
        // Execute the command and update state
        let result = try executeVimCommand(input, tempDir: tempDir)
        currentBuffer = result.finalText.isEmpty ? [""] : result.finalText.components(separatedBy: "\n")
        currentCursor = result.cursorPosition
        currentMode = result.mode
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
        
        // Determine the expected mode based on the command
        let expectedMode = determineExpectedMode(for: command)
        
        // Execute vim in Ex mode (the working approach)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "-u", vimrcPath,
            "-n", "-e", "-s",  // No swap, Ex mode, silent
            "-c", "call cursor(\(currentCursor.row + 1), \(currentCursor.col + 1))",
            "-c", "execute \"normal! \(escapedCommand)\"",
            "-c", "let cursor_pos = getpos('.')",
            "-c", "call writefile([cursor_pos[1] . ',' . cursor_pos[2] . ',' . '\(expectedMode)'], '\(cursorFile.path)')",
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
    
    private func determineExpectedMode(for command: String) -> String {
        // Analyze the command to determine the expected final mode
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for mode-changing commands
        if trimmedCommand == "i" || trimmedCommand.hasPrefix("i") {
            return "i"  // Insert mode
        } else if trimmedCommand == "a" || trimmedCommand.hasPrefix("a") {
            return "i"  // Insert mode (append)
        } else if trimmedCommand == "o" || trimmedCommand == "O" {
            return "i"  // Insert mode (open new line)
        } else if trimmedCommand == "R" || trimmedCommand.hasPrefix("R") {
            return "R"  // Replace mode
        } else if trimmedCommand == "v" || trimmedCommand == "V" || trimmedCommand.contains("v") {
            return "v"  // Visual mode
        } else if trimmedCommand.contains("\u{1b}") || trimmedCommand.contains("\\<Esc>") {
            return "n"  // Return to normal mode
        } else if trimmedCommand.hasPrefix(":") {
            return "n"  // Command mode returns to normal
        }
        
        // For most movement and text manipulation commands, we stay in normal mode
        return "n"
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
