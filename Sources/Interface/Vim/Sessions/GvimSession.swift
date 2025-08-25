/*
Author: <Chuanyu> (skewcy@gmail.com)
GvimSession.swift (c) 2025
Desc: GvimSession implementation using vim subprocess for automation
Created:  2025-08-22T03:16:23.191Z
*/

import Foundation

class GvimSession: SessionProtocol {
    private let gvimPath: String
    private var isSessionRunning = false
    private var tempDirectory: URL?
    private var serverName: String?
    private var serverProcess: Process?
    private var inputs: [String] = []
    private let sessionId: String
    
    init() {
        self.sessionId = UUID().uuidString
        self.gvimPath = "/opt/homebrew/bin/gvim"
    }

    func getSessionId() -> String {
        return sessionId
    }

    func getSessionType() -> SessionType {
        return .vim
    }

    func start() throws {
        guard !isSessionRunning else { return }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("GvimSession_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        self.tempDirectory = tempDir
        
        try startMacVimServer()
        
        Thread.sleep(forTimeInterval: 0.05)
        try sendServerCommand("\u{1b}:call setline(1, '')<CR>")
        try sendServerCommand("\u{1b}")
        
        isSessionRunning = true
    }
    
    func stop() {
        guard isSessionRunning else { return }
        
        if serverName != nil {
            try? sendServerCommand(":qall!<CR>")
            Thread.sleep(forTimeInterval: 0.1)
        }

        serverProcess?.terminate()
        serverProcess = nil
        
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
            tempDirectory = nil
        }
        
        serverName = nil
        isSessionRunning = false
    }
    
    func isRunning() -> Bool {
        return isSessionRunning
    }
    
    func sendInput(_ input: String) throws {
        inputs.append(input)
        guard isSessionRunning else {
            throw GvimSessionError.notRunning
        }
        
        try sendServerCommand(input)
    }
    
    func getInputs() throws -> [String] {
        return inputs
    }

    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String] {
        guard isRunning() else {
            throw GvimSessionError.notRunning
        }
        
        guard buffer == 0 || buffer == 1 else {
            throw GvimSessionError.invalidResponse("Invalid buffer number: \(buffer)")
        }
        
        return try queryBufferLines(start: start, end: end)
    }
    
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws {
        guard isRunning() else {
            throw GvimSessionError.notRunning
        }
        
        guard buffer == 0 || buffer == 1 else {
            throw GvimSessionError.invalidResponse("Invalid buffer number: \(buffer)")
        }
        
        try setBufferLinesViaVim(start: start, end: end, lines: lines)
    }
    
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int) {
        guard isRunning() else {
            throw GvimSessionError.notRunning
        }
        
        guard window == 0 else {
            throw GvimSessionError.invalidResponse("Invalid window number: \(window)")
        }
        
        return try queryServerCursor()
    }
    
    func setCursorPosition(window: Int, row: Int, col: Int) throws {
        guard isRunning() else {
            throw GvimSessionError.notRunning
        }
        
        guard window == 0 else {
            throw GvimSessionError.invalidResponse("Invalid window number: \(window)")
        }
        
        let vimRow = max(1, row + 1)
        let vimCol = max(1, col + 1)
        
        try sendServerCommand(":\(vimRow)<CR>")
        try sendServerCommand("\(vimCol)|")
    }
    
    func getMode() throws -> (mode: String, blocking: Bool) {
        guard isRunning() else {
            throw GvimSessionError.notRunning
        }
        let mode = try queryServerMode()
        return (mode: mode, blocking: false)
    }
    
    private func startMacVimServer() throws {
        let uniqueServerName = "VIMSESSION_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))"
        
        // Create a temporary file for the server
        guard let tempDir = tempDirectory else {
            throw GvimSessionError.notRunning
        }
        let tempFile = tempDir.appendingPathComponent("server_buffer.txt")
        try "".write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Start MacVim headless as server
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
        process.arguments = [
            "-n",
            "--servername", uniqueServerName,
            "-f",
            "--remote-tab", tempFile.path,
            "--cmd", "set nocompatible | set scrolloff=3 | set showcmd | set number | set ruler | set visualbell t_vb= | set novisualbell | set hlsearch | set incsearch | set showmatch | set ignorecase | set smartcase | set ai | set tabstop=2 | set shiftwidth=2 | set softtabstop=2 | set backspace=indent,eol,start | set nobackup | syntax on | filetype on | filetype indent on | filetype plugin indent on"
        ]
        
        // Redirect output to avoid GUI dialogs
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        try process.run()
        self.serverProcess = process
        self.serverName = uniqueServerName
        
        // Wait for server to be ready
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
            Thread.sleep(forTimeInterval: 0.1)
            attempts += 1
            
            do {
                let servers = try listVimServers()
                if servers.contains(uniqueServerName) {
                    // Server is ready
                    return
                }
            } catch {
                if attempts == maxAttempts {
                    throw GvimSessionError.startupFailed(error)
                }
            }
        }
        
        throw GvimSessionError.startupFailed(NSError(domain: "GvimSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "MacVim server failed to start after \(maxAttempts) attempts"]))
    }
    
    private func listVimServers() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
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
            throw GvimSessionError.communicationFailed("Failed to list servers: \(error)")
        }
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    private func sendServerCommand(_ command: String) throws {
        guard let serverName = serverName else {
            throw GvimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
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
            throw GvimSessionError.communicationFailed("Server send failed: \(error)")
        }
    }
    
    private func queryServerMode() throws -> String {
        guard let serverName = serverName else {
            throw GvimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
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
            throw GvimSessionError.communicationFailed("Mode query failed: \(error)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        let rawMode = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "") ?? "n"

        return rawMode
    }
    
    private func queryServerCursor() throws -> (row: Int, col: Int) {
        guard let serverName = serverName else {
            throw GvimSessionError.notRunning
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
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
            throw GvimSessionError.communicationFailed("Cursor query failed: \(error)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let components = result.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").components(separatedBy: ",")
        
        if components.count >= 4 {
            let row = max(0, (Int(components[1].trimmingCharacters(in: .whitespaces)) ?? 1) - 1)
            let col = max(0, (Int(components[2].trimmingCharacters(in: .whitespaces)) ?? 1) - 1)
            return (row: row, col: col)
        }

        throw GvimSessionError.invalidResponse("Failed to get cursor position: \(result)")
    }
    
    private func queryBufferLines(start: Int, end: Int) throws -> [String] {
        guard let serverName = serverName else {
            throw GvimSessionError.notRunning
        }
        
        let startLine = max(1, start + 1)
        let endLine = end == -1 ? "$" : String(end)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-expr", "join(getline(\(startLine), '\(endLine)'), \"\\n\")"
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
            throw GvimSessionError.communicationFailed("Buffer lines query failed: \(error)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Remove surrounding quotes if present
        let cleanResult = result.hasPrefix("'") && result.hasSuffix("'") ? 
            String(result.dropFirst().dropLast()) : result
        
        // Split by newlines to get individual lines
        let lines = cleanResult.components(separatedBy: "\n")
        return lines.isEmpty || (lines.count == 1 && lines[0].isEmpty) ? [""] : lines
    }
    
    private func setBufferLinesViaVim(start: Int, end: Int, lines: [String]) throws {
        // Use vim's setline() function to directly set the buffer content
        if end == -1 {
            // Replace entire buffer
            try sendServerCommand(":1,$d<CR>")
            if !lines.isEmpty {
                for (index, line) in lines.enumerated() {
                    let escapedLine = line.replacingOccurrences(of: "'", with: "''")
                    if index == 0 {
                        try sendServerCommand(":call setline(1, '\(escapedLine)')<CR>")
                    } else {
                        try sendServerCommand(":call append(line('$'), '\(escapedLine)')<CR>")
                    }
                }
            }
        } else {
            // Replace specific range
            let startLine = start + 1
            let endLine = end
            
            // Delete existing lines in range if they exist
            if startLine <= endLine {
                try sendServerCommand(":\(startLine),\(endLine)d<CR>")
            }
            
            // Insert new lines
            if !lines.isEmpty {
                let insertLine = max(1, start)
                for (index, line) in lines.enumerated() {
                    let escapedLine = line.replacingOccurrences(of: "'", with: "''")
                    let lineNum = insertLine + index
                    if lineNum == 1 && start == 0 {
                        try sendServerCommand(":call setline(1, '\(escapedLine)')<CR>")
                    } else {
                        try sendServerCommand(":call append(\(lineNum - 1), '\(escapedLine)')<CR>")
                    }
                }
            }
        }
    }
}

enum GvimSessionError: Error {
    case startupFailed(Error)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
}
