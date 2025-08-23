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
    
    func execKeystrokes(session: SessionProtocol, keystrokes: [VimKeystroke]) throws -> VimState {
        guard session.isRunning() else {
            throw VimEngineError.nvimNotRunning
        }

        var lastValidState = try getState(session: session) ?? VimState(buffer: [], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        
        for keystroke in keystrokes {
            if let currentState = try getState(session: session) {
                lastValidState = currentState
            }
            try session.sendInput(keystroke.rawValue)
        }
        
        return try getState(session: session) ?? lastValidState 
    }

    func execKeystrokes(_ keystrokes: [VimKeystroke]) throws -> VimState {
        let session = try sessionManager.createAndStartSession(type: defaultSessionType)

        if let defaultState = self.defaultState {
            try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: defaultState.buffer)
            try session.setCursorPosition(window: 0, row: defaultState.cursor.row, col: defaultState.cursor.col)
        }

        defer { 
            session.stop()
        }
        return try execKeystrokes(session: session, keystrokes: keystrokes)
    }
    
    func execKeystrokes(_ keystrokes: [VimKeystroke], sessionId: String) throws -> VimState {
        let session = try sessionManager.getSession(id: sessionId)
        
        if let defaultState = self.defaultState {
            try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: defaultState.buffer)
            try session.setCursorPosition(window: 0, row: defaultState.cursor.row, col: defaultState.cursor.col)
        }
        
        return try execKeystrokes(session: session, keystrokes: keystrokes)
    }
    
    func getState(session: SessionProtocol) throws -> VimState? {
        let modeInfo = try session.getMode()
        
        guard !modeInfo.blocking else { return nil }

        let vimMode = try getMode(session: session)
        let buffer = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        let cursor = try session.getCursorPosition(window: 0)
        
        return VimState(buffer: buffer, cursor: VimCursor(row: cursor.row, col: cursor.col), mode: vimMode)
    }
    
    func getMode(session: SessionProtocol) throws -> VimMode {
        let modeInfo = try session.getMode()
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