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

    // Batched state query to reduce RPC round-trips.
    // Returns: mode, blocking flag, full buffer lines, and cursor position (0-based row/col).
    func getStateBundle(buffer: Int, window: Int) async throws -> (mode: String, blocking: Bool, buffer: [String], cursor: (row: Int, col: Int))
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

// Provide a default implementation that calls individual RPCs.
// Concrete sessions can override with a more efficient batched call.
extension SessionProtocol {
    func getStateBundle(buffer: Int = 1, window: Int = 0) async throws -> (mode: String, blocking: Bool, buffer: [String], cursor: (row: Int, col: Int)) {
        // Always fetch mode first to detect blocking states that could hang other calls
        let modeInfo = try await getMode()
        if modeInfo.blocking {
            // Return early; callers should check `.blocking` and avoid using buffer/cursor
            return (mode: modeInfo.mode, blocking: true, buffer: [], cursor: (row: 0, col: 0))
        }
        let buf = try await getBufferLines(buffer: buffer, start: 0, end: -1)
        let cur = try await getCursorPosition(window: window)
        return (mode: modeInfo.mode, blocking: false, buffer: buf, cursor: cur)
    }
}
