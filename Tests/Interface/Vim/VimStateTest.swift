/*
Author: <Chuanyu> (skewcy@gmail.com)
VimStateTests.swift (c) 2025
Desc: Tests for VimState structure using Swift Testing
Created:  2025-08-19T20:15:34.781Z
*/

import Testing
@testable import VimCafe

struct VimStateTests {
    
    @Test func basicInitialization() {
        let state = VimState(
            buffer: ["Hello", "World"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        
        #expect(state.buffer == ["Hello", "World"])
        #expect(state.cursor.row == 0)
        #expect(state.cursor.col == 0)
        #expect(state.mode == .normal)
    }
    
    @Test func emptyBuffer() {
        let state = VimState(
            buffer: [],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        
        #expect(state.buffer.isEmpty)
        #expect(state.cursor.row == 0)
        #expect(state.cursor.col == 0)
    }
    
    @Test(arguments: [
        (["Single line"], 0, 5, VimMode.normal),
        (["Line 1", "Line 2", "Line 3"], 1, 2, VimMode.insert),
        (["Multiple", "lines", "buffer"], 2, 0, VimMode.visual)
    ])
    func parameterizedCreation(buffer: [String], cursorRow: Int, cursorCol: Int, mode: VimMode) {
        let state = VimState(buffer: buffer, cursor: VimCursor(row: cursorRow, col: cursorCol), mode: mode)
        
        #expect(state.buffer == buffer)
        #expect(state.cursor.row == cursorRow)
        #expect(state.cursor.col == cursorCol)
        #expect(state.mode == mode)
    }
    
    
    @Test func allModesAreHashable() {
        let modes: Set<VimMode> = [.normal, .insert, .visual, .command, .replace]
        #expect(modes.count == 5)
    }
    
    @Test func identicalStatesAreEqual() {
        let state1 = VimState(
            buffer: ["Hello", "World"],
            cursor: VimCursor(row: 1, col: 2),
            mode: .insert
        )
        let state2 = VimState(
            buffer: ["Hello", "World"],
            cursor: VimCursor(row: 1, col: 2),
            mode: .insert
        )
        
        #expect(state1 == state2)
    }
    
    @Test func differentStatesAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        let state2 = VimState(
            buffer: ["World"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        
        #expect(state1 != state2)
    }
    
    @Test func statesWithDifferentCursorsAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        let state2 = VimState(
            buffer: ["Hello"],
            cursor: VimCursor(row: 0, col: 1),
            mode: .normal
        )
        
        #expect(state1 != state2)
    }
    
    @Test func statesWithDifferentModesAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .normal
        )
        let state2 = VimState(
            buffer: ["Hello"],
            cursor: VimCursor(row: 0, col: 0),
            mode: .insert
        )
        
        #expect(state1 != state2)
    }
}

