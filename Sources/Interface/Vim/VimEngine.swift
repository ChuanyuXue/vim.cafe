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
    private let lru: VimStateLRU

    init(defaultState: VimState? = nil, sessionManager: SessionManager = .shared, defaultSessionType: SessionType = .nvim) {
        self.defaultState = defaultState
        self.sessionManager = sessionManager
        self.defaultSessionType = defaultSessionType
        self.lru = VimStateLRU(capacity: 1000)
    }
    
    func execKeystrokes(session: SessionProtocol, keystrokes: [VimKeystroke]) async throws -> VimState {
        guard await session.isRunning() else {
            throw VimEngineError.nvimNotRunning
        }

        try await session.sendInput(encodeKeystrokes(keystrokes))

        if let state = try await getState(session: session) {
            await lru.set(keystrokes, state)
            return state
        }

        var prefix = keystrokes
        while !prefix.isEmpty {
            prefix.removeLast()
            if let state = await lru.get(prefix) {
                return state
            }
        }

        return VimState(buffer: [], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    }

    func execKeystrokes(_ keystrokes: [VimKeystroke]) async throws -> VimState {
        let session = try await sessionManager.createAndStartSession(type: defaultSessionType, defaultState: defaultState)

        let result = try await execKeystrokes(session: session, keystrokes: keystrokes)
        try await session.stop()
        return result
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