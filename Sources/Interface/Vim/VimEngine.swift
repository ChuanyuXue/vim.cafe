/*
Author: <Chuanyu> (skewcy@gmail.com)
VimEngine.swift (c) 2025
Desc: VimEngine integrates with nvim headless RPC server
Created:  2025-08-18T00:34:23.451Z
*/

import Foundation

class VimEngine {
    private let defaultState: VimState?
    private let sessionManager: SessionManager
    private let defaultSessionType: SessionType
    
    init(defaultState: VimState? = nil, sessionManager: SessionManager = .shared, defaultSessionType: SessionType = .nvim) {
        self.defaultState = defaultState
        self.sessionManager = sessionManager
        self.defaultSessionType = defaultSessionType
    }
    
    func execKeystrokes(session: SessionProtocol, keystrokes: [VimKeystroke]) async throws -> VimState {
        guard await session.isRunning() else {
            throw VimEngineError.nvimNotRunning
        }

        let inputs = try await session.getInputs()
        try await session.sendInput(encodeKeystrokes(keystrokes))

        if let lastState = try await getState(session: session) {
            return lastState
        }


        // Use new session for recursive call
        let newSession = try await sessionManager.copySession(inputs: inputs, type: session.getSessionType())
        let result = try await execKeystrokes(session: newSession, keystrokes: Array(keystrokes[0..<keystrokes.count - 1]))
        await sessionManager.stopSession(id: newSession.getSessionId())
        return result
    }

    func execKeystrokes(_ keystrokes: [VimKeystroke]) async throws -> VimState {
        let session = try await sessionManager.createAndStartSession(type: defaultSessionType)

        if let defaultState = self.defaultState {
            try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: defaultState.buffer)
            try await session.setCursorPosition(window: 0, row: defaultState.cursor.row, col: defaultState.cursor.col)
        }

        let result = try await execKeystrokes(session: session, keystrokes: keystrokes)
        try await session.stop()
        return result
    }
    
    func execKeystrokes(_ keystrokes: [VimKeystroke], sessionId: String) async throws -> VimState {
        let session = try await sessionManager.getSession(id: sessionId)
        
        if let defaultState = self.defaultState {
            try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: defaultState.buffer)
            try await session.setCursorPosition(window: 0, row: defaultState.cursor.row, col: defaultState.cursor.col)
        }
        
        return try await execKeystrokes(session: session, keystrokes: keystrokes)
    }
    
    func getState(session: SessionProtocol) async throws -> VimState? {
        // Check if session is still running before attempting RPC calls
        guard await session.isRunning() else { return nil }
        
        do {
            let modeInfo = try await session.getMode()
            
            guard !modeInfo.blocking else { return nil }

            let vimMode = try await getMode(session: session)
            let buffer = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
            let cursor = try await session.getCursorPosition(window: 0)
            
            return VimState(buffer: buffer, cursor: VimCursor(row: cursor.row, col: cursor.col), mode: vimMode)
        } catch {
            // If RPC calls fail (likely due to process termination), return nil
            return nil
        }
    }
    
    func getMode(session: SessionProtocol) async throws -> VimMode {
        let modeInfo = try await session.getMode()
        guard let vimMode = VimMode(rawValue: modeInfo.mode) else {
            throw VimEngineError.invalidResponse("Unknown mode: \(modeInfo.mode)")
        }
        return vimMode
    }
}

enum VimEngineError: Error {
    case nvimStartupFailed(Error)
    case invalidResponse(String)
    case nvimNotRunning
}