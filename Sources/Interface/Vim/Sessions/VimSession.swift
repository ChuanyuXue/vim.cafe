/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSession.swift (c) 2025
Desc: VimSession implementation using vim subprocess for automation
Created:  2025-08-22T03:16:23.191Z
*/

import Foundation

class VimSession: VimSessionProtocol {
    private let gvimPath: String
    private let vimrcPath: String
    private var isSessionRunning = false
    private var tempDirectory: URL?
    private var serverName: String?
    private var serverProcess: Process?
    
    // Current session state
    private var currentBuffer: [String] = [""]
    private var currentCursor: (row: Int, col: Int) = (0, 0)
    private var currentMode: String = "n"
    
    init(gvimPath: String? = nil) {
        if let customPath = gvimPath {
            self.gvimPath = customPath
        } else {
            let possibleGvimPaths = [
                "/opt/homebrew/bin/gvim",
                "/usr/local/bin/gvim",
                "/Applications/MacVim.app/Contents/bin/gvim"
            ]
            
            guard let foundPath = possibleGvimPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                fatalError("gvim not found in any of the expected locations")
            }
            self.gvimPath = foundPath
        }
        
        let bundlePath = Bundle.main.bundlePath
        self.vimrcPath = bundlePath.isEmpty ? "Sources/Interface/Golf/vimgolf.vimrc" : bundlePath + "/../../Sources/Interface/Golf/vimgolf.vimrc"
    }
    
    func start() throws {
        guard !isSessionRunning else { return }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VimSession_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        self.tempDirectory = tempDir
        
        try startMacVimServer()
        
        currentBuffer = [""]
        currentCursor = (0, 0)
        currentMode = "n"
        isSessionRunning = true
    }
    
    func stop() {
        guard isSessionRunning else { return }
        
        try? sendServerCommand(":qall!")
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
        guard isSessionRunning else {
            throw VimSessionError.notRunning
        }
        
        var commandToSend = input
        
        if input.hasPrefix(":") && !input.contains("<CR>") && !input.contains("\\<CR>") && !input.hasSuffix("\n") && !input.hasSuffix("\r") {
            commandToSend = input + "<CR>"
        }
        
        try sendServerCommand(commandToSend)
        
        Thread.sleep(forTimeInterval: 0.05)
        
        let realMode = try queryServerMode()
        currentMode = realMode
        
        let cursorInfo = try queryServerCursor()
        currentCursor = cursorInfo
    }
    
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String] {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
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
        
        guard window == 0 else {
            throw VimSessionError.invalidResponse("Invalid window number: \(window)")
        }
        
        return currentCursor
    }
    
    func setCursorPosition(window: Int, row: Int, col: Int) throws {
        guard isRunning() else {
            throw VimSessionError.notRunning
        }
        
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
    
    private func startMacVimServer() throws {
        let uniqueServerName = "VIMSESSION_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))"
        
        // Create a temporary file for the server
        guard let tempDir = tempDirectory else {
            throw VimSessionError.notRunning
        }
        let tempFile = tempDir.appendingPathComponent("server_buffer.txt")
        try "".write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Start MacVim headless as server
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gvimPath)
        process.arguments = [
            "--servername", uniqueServerName,
            "--remote-tab-silent", tempFile.path,
            "-u", vimrcPath,
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
            throw VimSessionError.communicationFailed("Failed to list servers: \(error)")
        }
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    private func sendServerCommand(_ command: String) throws {
        guard let serverName = serverName else {
            throw VimSessionError.notRunning
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
            throw VimSessionError.communicationFailed("Server send failed: \(error)")
        }
    }
    
    private func queryServerMode() throws -> String {
        guard let serverName = serverName else {
            throw VimSessionError.notRunning
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
}

enum VimSessionError: Error {
    case startupFailed(Error)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
}
