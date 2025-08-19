/*
Author: <Chuanyu> (skewcy@gmail.com)
VimEngine.swift (c) 2025
Desc: VimEngine integrates with nvim headless RPC server
Created:  2025-08-18T00:34:23.451Z
*/

import Foundation

class VimEngine {
    private let nvimClient: NvimClientProtocol
    private var currentBuffer: Int = 1
    
    init(state: VimState, nvimClient: NvimClientProtocol = NvimClient()) throws {
        self.nvimClient = nvimClient
        try nvimClient.start()
        try setInitialState(state)
    }
    
    deinit {
        nvimClient.stop()
    }
}

extension VimEngine {
    func setInitialState(_ state: VimState) throws {
        try nvimClient.setBufferLines(buffer: currentBuffer, start: 0, end: -1, lines: state.buffer)
        try nvimClient.setCursorPosition(window: 0, row: state.cursorRow, col: state.cursorCol)
    }
    
    func execKeystrokes(_ keystrokes: [String]) throws -> VimState {
        var lastValidState = try getCurrentState() ?? VimState(buffer: [], cursorRow: 0, cursorCol: 0, mode: "n")
        
        for keystroke in keystrokes {
            if let currentState = try getCurrentState() {
                lastValidState = currentState
            }
            try nvimClient.sendInput(keystroke)
        }
        
        return try getCurrentState() ?? lastValidState
    }
    
    func getCurrentState() throws -> VimState? {
        let modeInfo = try nvimClient.getMode()
        guard !modeInfo.blocking else { return nil }
        
        let buffer = try nvimClient.getBufferLines(buffer: currentBuffer, start: 0, end: -1)
        let cursor = try nvimClient.getCursorPosition(window: 0)
        
        return VimState(buffer: buffer, cursorRow: cursor.row, cursorCol: cursor.col, mode: modeInfo.mode)
    }
}


enum VimEngineError: Error {
    case nvimStartupFailed(Error)
    case invalidResponse(String)
    case nvimNotRunning
}