/*
Author: <Chuanyu> (skewcy@gmail.com)
SessionManager.swift (c) 2025
Desc: Factory for managing and creating vim/nvim sessions
Created:  2025-08-23T00:00:00.000Z
*/

import Foundation

actor SessionManager {
    static let shared = SessionManager()
    
    private var sessions: [String: SessionProtocol] = [:]
    
    private init() {}
    
    func createAndStartSession(type: SessionType) async throws -> SessionProtocol {
        let session = try await createSessionInstance(type: type)
        
        try await session.start()
        
        sessions[session.getSessionId()] = session
        return session
    }

    func createAndStartSession(type: SessionType, defaultState: VimState?) async throws -> SessionProtocol {
        let session = try await createSessionInstance(type: type)

        try await session.start()

        if let defaultState = defaultState {
            try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: defaultState.buffer)
            try await session.setCursorPosition(window: 0, row: defaultState.cursor.row, col: defaultState.cursor.col)
        }

        sessions[session.getSessionId()] = session
        return session
    }

    func copySession(id: String) async throws -> SessionProtocol {
        let session = try await getSession(id: id)
        let type = session.getSessionType()

        let newSession = try await createAndStartSession(type: type)

        let inputs = try await session.getInputs()
        for input in inputs {
            try await newSession.sendInput(input)
        }

        sessions[newSession.getSessionId()] = newSession

        return newSession
    }

    func copySession(inputs: [String], type: SessionType) async throws -> SessionProtocol {
        let newSession = try await createAndStartSession(type: type)
        for input in inputs {
            try await newSession.sendInput(input)
        }
        sessions[newSession.getSessionId()] = newSession
        return newSession
    }
    
    func getSession(id: String) async throws -> SessionProtocol {
        guard let session = sessions[id] else {
            throw SessionManagerError.sessionNotFound(id)
        }
        
        return session
    }
    
    func stopSession(id: String) async {
        if let session = sessions[id] {
            try? await session.stop()
            sessions.removeValue(forKey: id)
        }
    }
    
    func stopAllSessions() async {
        for session in sessions.values {
            try? await session.stop()
        }
        sessions.removeAll()
    }
    
    func activeSessionCount() async -> Int {
        return sessions.count
    }
    
    private func createSessionInstance(type: SessionType) async throws -> SessionProtocol {
        switch type {
        case .vim:
            return GvimSession()
        case .nvim:
            return NvimSession()
        }
    }
}

enum SessionManagerError: Error {
    
    case sessionNotFound(String)
    case noViableSessionType(originalError: Error)
    case sessionCreationFailed(SessionType, Error)
}