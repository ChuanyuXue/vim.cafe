/*
Author: <Chuanyu> (skewcy@gmail.com)
GvimSession.swift (c) 2025
Desc: description
Created:  2025-08-19T20:42:35.611Z
*/

protocol SessionProtocol {
    func getSessionType() -> SessionType
    func getSessionId() -> String

    func start() throws
    func stop()
    func isRunning() -> Bool

    func sendInput(_ input: String) throws
    func getInputs() throws -> [String]
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String]
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int)
    func setCursorPosition(window: Int, row: Int, col: Int) throws
    func getMode() throws -> (mode: String, blocking: Bool)
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