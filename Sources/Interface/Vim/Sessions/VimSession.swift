/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSession.swift (c) 2025
Desc: VimSession implementation using vim subprocess for automation
Created:  2025-08-22T03:16:23.191Z
*/

import Foundation

class VimSession: VimSessionProtocol {
    private var vimProcess: Process?
    private let vimPath: String
    private let serverName: String
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
            // Try common vim locations
            let possiblePaths = [
                "/opt/homebrew/bin/vim",
                "/usr/local/bin/vim", 
                "/usr/bin/vim"
            ]
            
            self.vimPath = possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/vim"
        }
        
        self.serverName = "VimSession_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))"
        
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
        
        vimProcess?.terminate()
        vimProcess = nil
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
        let scriptFile = tempDir.appendingPathComponent("script.vim")
        
        // Write current buffer to input file
        let inputText = currentBuffer.joined(separator: "\n")
        try inputText.write(to: inputFile, atomically: true, encoding: .utf8)
        
        // Create vim script that captures mode directly after command execution
        let escapedCommand = escapeVimInput(command)
        let script = """
        " Set cursor to current position
        call cursor(\(currentCursor.row + 1), \(currentCursor.col + 1))
        
        " Execute the command
        execute "normal! \(escapedCommand)"
        
        " Immediately capture the mode after command execution
        let current_mode = mode()
        
        " Write output file
        write! \(outputFile.path)
        
        " Write cursor position and mode
        let cursor_pos = getpos('.')
        call writefile([cursor_pos[1] . ',' . cursor_pos[2] . ',' . current_mode], '\(cursorFile.path)')
        
        " Quit
        qall!
        """
        
        try script.write(to: scriptFile, atomically: true, encoding: .utf8)
        
        // Execute vim with stdin input to preserve mode detection
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "-u", vimrcPath,
            "-n",  // No swap file
            "+set nocp",  // No compatible mode
            "+set t_ti= t_te=",  // Disable terminal initialization
            inputFile.path
        ]
        
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // Send the script commands via stdin
            let stdinHandle = inputPipe.fileHandleForWriting
            
            // Use a function that can capture mode during execution
            let stdinCommands = """
            :function! ExecuteAndCapture()
            :  call cursor(\(currentCursor.row + 1), \(currentCursor.col + 1))
            :  execute "normal! \(escapedCommand)"
            :  let l:captured_mode = mode()
            :  let l:cursor_pos = getpos('.')
            :  call writefile([l:cursor_pos[1] . ',' . l:cursor_pos[2] . ',' . l:captured_mode], '\(cursorFile.path)')
            :  write! \(outputFile.path)
            :endfunction
            :call ExecuteAndCapture()
            :qall!
            """
            
            stdinHandle.write(stdinCommands.data(using: .utf8)!)
            stdinHandle.closeFile()
            
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
