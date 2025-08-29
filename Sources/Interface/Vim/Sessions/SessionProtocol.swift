/*
Author: <Chuanyu> (skewcy@gmail.com)
GvimSession.swift (c) 2025
Desc: description
Created:  2025-08-19T20:42:35.611Z
*/

protocol SessionProtocol {
    func getSessionType() -> SessionType
    func getSessionId() -> String

    func start() async throws
    func stop() async throws
    func isRunning() async -> Bool

    func sendInput(_ input: String) async throws
    func getInputs() async throws -> [String]
    func getBufferLines(buffer: Int, start: Int, end: Int) async throws -> [String]
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) async throws
    func getCursorPosition(window: Int) async throws -> (row: Int, col: Int)
    func setCursorPosition(window: Int, row: Int, col: Int) async throws
    func getMode() async throws -> (mode: String, blocking: Bool)
}

enum SessionType: String, CaseIterable {
    case nvim = "nvim"
    case vim = "vim"
    
    var displayName: String {
        switch self {
        case .vim:
            return "Vim"
        case .nvim:
            return "Neovim"
        }
    }
}