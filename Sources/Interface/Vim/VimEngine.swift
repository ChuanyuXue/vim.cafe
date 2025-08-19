/*
Author: <Chuanyu> (skewcy@gmail.com)
VimEngine.swift (c) 2025
Desc: VimEngine integrates with nvim headless RPC server
Created:  2025-08-18T00:34:23.451Z
*/

import Foundation

class VimEngine {
    func execKeystrokes(session: VimSessionProtocol, keystrokes: [String]) throws -> VimState {
        guard session.isRunning() else {
            throw VimEngineError.nvimNotRunning
        }

        var lastValidState = try getState(session: session) ?? VimState(buffer: [], cursorRow: 0, cursorCol: 0, mode: "n")
        
        for keystroke in keystrokes {
            if let currentState = try getState(session: session) {
                lastValidState = currentState
            }
            try session.sendInput(keystroke)
        }
        
        return try getState(session: session) ?? lastValidState 
    }

    func execKeystrokes(_ keystrokes: [String]) throws -> VimState {
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        return try execKeystrokes(session: session, keystrokes: keystrokes)
    }
    
    func getState(session: VimSessionProtocol) throws -> VimState? {
        let modeInfo = try session.getMode()
        guard !modeInfo.blocking else { return nil }
        
        let buffer = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        let cursor = try session.getCursorPosition(window: 0)
        
        return VimState(buffer: buffer, cursorRow: cursor.row, cursorCol: cursor.col, mode: modeInfo.mode)
    }
}


enum VimEngineError: Error {
    case nvimStartupFailed(Error)
    case invalidResponse(String)
    case nvimNotRunning
}