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
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        
        #expect(state.buffer == ["Hello", "World"])
        #expect(state.cursorRow == 0)
        #expect(state.cursorCol == 0)
        #expect(state.mode == "n")
    }
    
    @Test func emptyBuffer() {
        let state = VimState(
            buffer: [],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        
        #expect(state.buffer.isEmpty)
        #expect(state.cursorRow == 0)
        #expect(state.cursorCol == 0)
    }
    
    @Test(arguments: [
        (["Single line"], 0, 5, "n"),
        (["Line 1", "Line 2", "Line 3"], 1, 2, "i"),
        (["Multiple", "lines", "buffer"], 2, 0, "v")
    ])
    func parameterizedCreation(buffer: [String], cursorRow: Int, cursorCol: Int, mode: String) {
        let state = VimState(buffer: buffer, cursorRow: cursorRow, cursorCol: cursorCol, mode: mode)
        
        #expect(state.buffer == buffer)
        #expect(state.cursorRow == cursorRow)
        #expect(state.cursorCol == cursorCol)
        #expect(state.mode == mode)
    }
    
    
    @Test func allModesAreHashable() {
        let modes: Set<String> = ["n", "i", "v", "c", "R"]
        #expect(modes.count == 5)
    }
    
    @Test func identicalStatesAreEqual() {
        let state1 = VimState(
            buffer: ["Hello", "World"],
            cursorRow: 1, cursorCol: 2,
            mode: "i"
        )
        let state2 = VimState(
            buffer: ["Hello", "World"],
            cursorRow: 1, cursorCol: 2,
            mode: "i"
        )
        
        #expect(state1 == state2)
    }
    
    @Test func differentStatesAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        let state2 = VimState(
            buffer: ["World"],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        
        #expect(state1 != state2)
    }
    
    @Test func statesWithDifferentCursorsAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        let state2 = VimState(
            buffer: ["Hello"],
            cursorRow: 0, cursorCol: 1,
            mode: "n"
        )
        
        #expect(state1 != state2)
    }
    
    @Test func statesWithDifferentModesAreNotEqual() {
        let state1 = VimState(
            buffer: ["Hello"],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        let state2 = VimState(
            buffer: ["Hello"],
            cursorRow: 0, cursorCol: 0,
            mode: "i"
        )
        
        #expect(state1 != state2)
    }
}

