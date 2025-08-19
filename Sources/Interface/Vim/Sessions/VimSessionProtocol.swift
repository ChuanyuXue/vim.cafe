/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSession.swift (c) 2025
Desc: description
Created:  2025-08-19T20:42:35.611Z
*/

protocol VimSessionProtocol {
    func start() throws
    func stop()
    func isRunning() -> Bool

    func sendInput(_ input: String) throws
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String]
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int)
    func setCursorPosition(window: Int, row: Int, col: Int) throws
    func getMode() throws -> (mode: String, blocking: Bool)
}