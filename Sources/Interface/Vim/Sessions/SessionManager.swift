/*
Author: <Chuanyu> (skewcy@gmail.com)
SessionManager.swift (c) 2025
Desc: Factory for managing and creating vim/nvim sessions
Created:  2025-08-23T00:00:00.000Z
*/

import Foundation

class SessionManager {
    static let shared = SessionManager()
    
    private var sessions: [String: SessionProtocol] = [:]
    private let sessionQueue = DispatchQueue(label: "session.manager.queue", attributes: .concurrent)
    
    private init() {}
    
    func createAndStartSession(type: SessionType) throws -> SessionProtocol {
        let session = try createSessionInstance(type: type)
        
        try session.start()
        
        sessionQueue.async(flags: .barrier) {
            self.sessions[session.getSessionId()] = session
        }
        return session
    }

    func copySession(id: String) throws -> SessionProtocol {
        let session = try getSession(id: id)
        let type = session.getSessionType()

        let newSession = try createAndStartSession(type: type)

        let inputs = try session.getInputs()
        for input in inputs {
            try newSession.sendInput(input)
        }

        sessionQueue.async(flags: .barrier) {
            self.sessions[newSession.getSessionId()] = newSession
        }

        return newSession
    }

    func copySession(inputs: [String], type: SessionType) throws -> SessionProtocol {
        let newSession = try createAndStartSession(type: type)
        for input in inputs {
            try newSession.sendInput(input)
        }
        sessionQueue.async(flags: .barrier) {
            self.sessions[newSession.getSessionId()] = newSession
        }
        return newSession
    }
    
    func getSession(id: String) throws -> SessionProtocol {
        let session = sessionQueue.sync {
            return sessions[id]
        }
        
        guard let session = session else {
            throw SessionManagerError.sessionNotFound(id)
        }
        
        return session
    }
    
    func stopSession(id: String) {
        sessionQueue.async(flags: .barrier) {
            if let session = self.sessions[id] {
                session.stop()
                self.sessions.removeValue(forKey: id)
            }
        }
    }
    
    func stopAllSessions() {
        sessionQueue.async(flags: .barrier) {
            for session in self.sessions.values {
                session.stop()
            }
            self.sessions.removeAll()
        }
    }
    
    func activeSessionCount() -> Int {
        return sessionQueue.sync {
            return sessions.count
        }
    }
    
    private func createSessionInstance(type: SessionType) throws -> SessionProtocol {
        switch type {
        case .vim:
            return VimSession()
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