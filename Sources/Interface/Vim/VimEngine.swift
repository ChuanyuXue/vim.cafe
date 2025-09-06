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

        signal(SIGPIPE, SIG_IGN)
    }
    
    func execKeystrokes(session: SessionProtocol, keystrokes: [VimKeystroke]) async throws -> VimState {
        guard await session.isRunning() else {
            throw VimEngineError.nvimNotRunning
        }

        // Empty keystrokes, return default state
        if keystrokes.isEmpty {
            return defaultState ?? VimState(buffer: [], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        }

        // Copy inputs in case of 
        let inputs = try await session.getInputs()

        // 1) Keystrokes state is in cache
        if inputs == [], let state = await lru.get(keystrokes) {
            return state
        }

        // 2) Keystrokes state not in cache, execute keystrokes and no blocking
        try await session.sendInput(encodeKeystrokes(keystrokes))
        if let state = try await getState(session: session) {
            await lru.set(keystrokes, state)
            return state
        }

        // 3) Blocking, find the prefix in the cache
        if inputs == [], let state = await lru.get(Array(keystrokes.dropLast())) {
            // Update cache keystrokes == prefix when blocking
            await lru.set(keystrokes, state)
            return state
        }

        // 4) Prefix not in cache, fall back
        // Copy a new session and execute the last keystroke
        let newSession = try await sessionManager.copySession(inputs: inputs, type: session.getSessionType())
        let state = try await execKeystrokes(session: newSession, keystrokes: Array(keystrokes.dropLast()))
        await sessionManager.stopSession(id: newSession.getSessionId())
        return state
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
        let vimMode = VimMode(rawValue: modeInfo.mode)!
        return vimMode
    }
}

enum VimEngineError: Error {
    case nvimStartupFailed(Error)
    case nvimNotRunning
}