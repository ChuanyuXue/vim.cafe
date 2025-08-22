/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSession.swift (c) 2025
Desc: Vim client-server interface using Vimscript expressions
Created:  2025-08-19T20:42:35.611Z
*/

import Foundation

class VimSession: VimSessionProtocol {
    private var vimProcess: Process?
    private let serverName: String
    private let vimPath: String
    
    init(vimPath: String? = nil, serverName: String? = nil) {
        // Find vim executable in common locations
        if let providedPath = vimPath {
            self.vimPath = providedPath
        } else {
            let commonPaths = ["/usr/bin/vim", "/opt/homebrew/bin/vim", "/usr/local/bin/vim"]
            self.vimPath = commonPaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/vim"
        }
        
        // Generate unique server name for each session
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let randomId = Int.random(in: 1000...9999)
        self.serverName = serverName ?? "VIM_SESSION_\(ProcessInfo.processInfo.processIdentifier)_\(timestamp)_\(randomId)"
    }
    
    func start() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        
        // Start Vim in server mode with minimal configuration
        process.arguments = [
            "--servername", serverName,
            "-u", "NONE",  // Don't load any vimrc
            "--not-a-term",
            "+set noswapfile",
            "+set nobackup",
            "+set nowritebackup",
            "+set nocompatible"
        ]
        
        process.standardInput = Pipe()
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            self.vimProcess = process
            
            // Wait a moment for Vim to initialize
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify server is running
            if !isServerRunning() {
                throw VimSessionError.startupFailed("Vim server failed to start")
            }
        } catch {
            if let e = error as? VimSessionError {
                throw e
            }
            throw VimSessionError.startupFailed("Process launch failed: \(error)")
        }
    }
    
    func stop() {
        // Send quit command to Vim
        _ = try? executeRemote("qa!")
        
        // Give it a moment to shut down gracefully
        Thread.sleep(forTimeInterval: 0.1)
        
        // Force terminate if still running
        if vimProcess?.isRunning == true {
            vimProcess?.terminate()
        }
        
        vimProcess = nil
    }
    
    func isRunning() -> Bool {
        return vimProcess?.isRunning == true && isServerRunning()
    }
    
    func sendInput(_ input: String) throws {
        // Escape special characters for Vim
        let escaped = input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        // Use feedkeys() to send input to Vim
        try executeRemote("feedkeys(\"\(escaped)\", 'n')")
    }
    
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String] {
        // Vim uses 1-based line numbering
        let vimStart = start + 1
        let vimEnd = (end == -1) ? "$" : "\(end)"
        
        let expr = "getbufline(\(buffer), \(vimStart), '\(vimEnd)')"
        let result = try executeRemoteExpr(expr)
        
        // Parse the result into lines
        return parseVimList(result)
    }
    
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws {
        if lines.isEmpty {
            // Clear the buffer
            let vimStart = start + 1
            let vimEnd = (end == -1) ? "$" : "\(end + 1)"
            try executeRemote("call deletebufline(\(buffer), \(vimStart), \(vimEnd))")
            return
        }
        
        // Convert lines to Vim list format
        let vimList = lines.map { line in
            "'" + line
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "''") + "'"
        }.joined(separator: ", ")
        
        let vimStart = start + 1
        let vimEnd = (end == -1) ? "$" : "\(end + 1)"
        
        // Delete existing lines first
        if end == -1 {
            // Delete from start to end of buffer
            try executeRemote("call deletebufline(\(buffer), \(vimStart), '$')")
        } else if start < end {
            // Delete specific range
            try executeRemote("call deletebufline(\(buffer), \(vimStart), \(vimEnd))")
        }
        
        // Add new lines
        let expr = "appendbufline(\(buffer), \(start), [\(vimList)])"
        try executeRemote("call \(expr)")
    }
    
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int) {
        // Get cursor position (window parameter is ignored for simplicity)
        let line = try executeRemoteExpr("line('.')")
        let col = try executeRemoteExpr("col('.')")
        
        guard let lineNum = Int(line.trimmingCharacters(in: .whitespacesAndNewlines)),
              let colNum = Int(col.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw VimSessionError.invalidResponse("Failed to parse cursor position")
        }
        
        // Convert to 0-based indexing
        return (row: lineNum - 1, col: colNum - 1)
    }
    
    func setCursorPosition(window: Int, row: Int, col: Int) throws {
        // Set cursor position (convert to 1-based) - window parameter ignored for simplicity
        try executeRemote("call cursor(\(row + 1), \(col + 1))")
    }
    
    func getMode() throws -> (mode: String, blocking: Bool) {
        let modeResult = try executeRemoteExpr("mode(1)")
        let mode = modeResult.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Vim mode() returns different characters for different modes
        // n = normal, i = insert, v = visual, etc.
        let blocking = mode.contains("r") || mode.contains("!")
        
        return (mode: mode, blocking: blocking)
    }
    
    // MARK: - Private Helper Methods
    
    private func isServerRunning() -> Bool {
        let checkProcess = Process()
        checkProcess.executableURL = URL(fileURLWithPath: vimPath)
        checkProcess.arguments = ["--serverlist"]
        
        let pipe = Pipe()
        checkProcess.standardOutput = pipe
        checkProcess.standardError = Pipe()
        
        do {
            try checkProcess.run()
            checkProcess.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains(serverName)
            }
        } catch {
            return false
        }
        
        return false
    }
    
    private func executeRemote(_ command: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-send",
            ":\(command)<CR>"
        ]
        
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw VimSessionError.communicationFailed("Remote command failed: \(command)")
        }
    }
    
    private func executeRemoteExpr(_ expression: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: vimPath)
        process.arguments = [
            "--servername", serverName,
            "--remote-expr",
            expression
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw VimSessionError.communicationFailed("Remote expression failed: \(expression)")
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw VimSessionError.invalidResponse("Failed to decode expression result")
        }
        
        return output
    }
    
    private func parseVimList(_ vimOutput: String) -> [String] {
        let trimmed = vimOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle empty buffer case
        if trimmed.isEmpty {
            return [""]
        }
        
        // Vim lists are output with newlines between elements
        let lines = trimmed.components(separatedBy: .newlines)
        
        // Filter out completely empty responses but preserve empty lines in buffer
        if lines.count == 1 && lines[0].isEmpty {
            return [""]
        }
        
        return lines
    }
}

enum VimSessionError: Error, LocalizedError {
    case startupFailed(String)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
    
    var errorDescription: String? {
        switch self {
        case .startupFailed(let msg):
            return "Failed to start Vim session: \(msg)"
        case .communicationFailed(let msg):
            return "Communication with Vim failed: \(msg)"
        case .invalidResponse(let msg):
            return "Invalid response from Vim: \(msg)"
        case .notRunning:
            return "Vim session is not running"
        }
    }
}