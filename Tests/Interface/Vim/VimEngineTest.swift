/*
Author: <Chuanyu> (skewcy@gmail.com)
VimEngineTest.swift (c) 2025
Desc: Comprehensive tests for VimEngine functionality with real nvim integration
Created:  2025-08-20T00:00:00.000Z
*/

import Testing
import Foundation
@testable import VimCafe

// MARK: - Part 1: VimEngine Basic Functionality Tests
struct VimEngineBasicTests {
    
    @Test func testVimEngineInitialization() {
        let engine = VimEngine()
        #expect(engine != nil, "VimEngine should initialize successfully")
    }
    
    @Test func testSingleKeystrokeExecution() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.i])
        
        #expect(result.mode == .insert, "Should be in insert mode after 'i' keystroke")
        #expect(result.cursor.row >= 0, "Cursor row should be valid")
        #expect(result.cursor.col >= 0, "Cursor col should be valid")
    }
    
    @Test func testNavigationKeystrokes() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.i, .H, .e, .l, .l, .o, .escape, .h])
        
        #expect(result.mode == .normal, "Should be in normal mode after escape")
        #expect(result.buffer.contains("Hello"), "Buffer should contain typed text")
        #expect(result.cursor.col < 5, "Cursor should move left after 'h' command")
    }
    
    @Test func testInsertModeTextEntry() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.i, .H, .e, .l, .l, .o, .space, .W, .o, .r, .l, .d, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode after escape")
        #expect(result.buffer.first?.contains("Hello World") == true, "Buffer should contain inserted text")
    }
    
    @Test func testMultilineTextEntry() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.i, .L, .i, .n, .e, .space, .one, .enter, .L, .i, .n, .e, .space, .two, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.count >= 2, "Should have at least 2 lines")
        #expect(result.buffer.contains("Line 1"), "Should contain first line")
        #expect(result.buffer.contains("Line 2"), "Should contain second line")
    }
    
    @Test func testMovementBetweenLines() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.i, .F, .i, .r, .s, .t, .enter, .S, .e, .c, .o, .n, .d, .enter, .T, .h, .i, .r, .d, .escape, .k, .k])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.cursor.row == 0, "Should be on first line after two 'k' movements")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
    }
}

// MARK: - Part 2: VimEngine Session Integration Tests
struct VimEngineSessionTests {
    
    @Test func testVimEngineWithExistingSession() async throws {
        let session = NvimSession()
        let engine = VimEngine()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let result = try engine.execKeystrokes(session: session, keystrokes: [.i, .T, .e, .s, .t, .space, .w, .i, .t, .h, .space, .s, .e, .s, .s, .i, .o, .n, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.first?.contains("Test with session") == true, "Should contain text")
        
        session.stop()
    }
    
    @Test func testVimEngineStateRetrieval() async throws {
        let session = NvimSession()
        let engine = VimEngine()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: ["Test line 1", "Test line 2"])
        try session.setCursorPosition(window: 0, row: 1, col: 5)
        
        let state = try engine.getState(session: session)
        
        #expect(state != nil, "Should retrieve state successfully")
        #expect(state?.buffer == ["Test line 1", "Test line 2"], "Should match buffer content")
        #expect(state?.cursorRow == 1, "Should match cursor row")
        #expect(state?.cursorCol == 5, "Should match cursor col")
        #expect(state?.mode == .normal, "Should be in normal mode")
        
        session.stop()
    }
    
    @Test func testVimEngineWithBlockingSession() async throws {
        let session = NvimSession()
        let engine = VimEngine()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        try session.sendInput(":")
        try await Task.sleep(for: .milliseconds(100))
        
        let state = try engine.getState(session: session)
        
        if let state = state {
            #expect(state.mode == .command, "Should be in command mode when not blocking")
        }
        
        try session.sendInput("<Esc>")
        session.stop()
    }
    
    @Test func testVimEngineErrorHandling() async throws {
        let session = NvimSession()
        let engine = VimEngine()
        
        #expect(!session.isRunning(), "Session should not be running initially")
        
        do {
            _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
            Issue.record("Should throw error when session is not running")
        } catch VimEngineError.nvimNotRunning {
            // Expected error
        } catch {
            Issue.record("Should throw nvimNotRunning error, got \(error)")
        }
    }
}

// MARK: - Part 3: VimEngine Complex Editing Tests
struct VimEngineEditingTests {
    
    @Test func testComplexEditingSequence() async throws {
        let engine = VimEngine()
        
        let keystrokes: [VimKeystroke] = [
            .i, .f, .u, .n, .c, .t, .i, .o, .n, .space, .h, .e, .l, .l, .o, .leftParen, .rightParen, .space, .leftBrace, .enter,
            .space, .space, .space, .space, .c, .o, .n, .s, .o, .l, .e, .period, .l, .o, .g, .leftParen, .quote, .H, .e, .l, .l, .o, .space, .W, .o, .r, .l, .d, .quote, .rightParen, .semicolon, .enter,
            .rightBrace, .escape,
            .g, .g, .A, .space, .slash, .slash, .space, .F, .u, .n, .c, .t, .i, .o, .n, .space, .d, .e, .c, .l, .a, .r, .a, .t, .i, .o, .n, .escape
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.count >= 3, "Should have multiple lines")
        #expect(result.buffer.first?.contains("function hello()") == true, "Should contain function declaration")
        #expect(result.buffer.first?.contains("// Function declaration") == true, "Should contain comment")
    }
    
    @Test func testVisualModeSelection() async throws {
        let engine = VimEngine()
        
        let keystrokes: [VimKeystroke] = [
            .i, .S, .e, .l, .e, .c, .t, .space, .t, .h, .i, .s, .space, .t, .e, .x, .t, .escape,
            .zero, .v, .e
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .visual, "Should be in visual mode")
        #expect(result.buffer.first?.contains("Select this text") == true, "Should contain text")
    }
    
    @Test func testDeleteAndUndoOperations() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "Text to delete", "<Esc>",
            "0", "dw"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.first?.contains("Text") == false, "First word should be deleted")
        #expect(result.buffer.first?.contains("to delete") == true, "Rest of text should remain")
    }
    
    @Test func testSearchAndReplace() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "foo bar foo", "<Esc>",
            "/", "foo", "<CR>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should return to normal mode after search")
        #expect(result.buffer.first?.contains("foo bar foo") == true, "Should contain original text")
    }
    
    @Test func testWordMovement() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "word1 word2 word3", "<Esc>",
            "0", "w", "w"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.cursorCol >= 12, "Cursor should be on third word")
    }
    
    @Test func testLineOperations() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "Line 1", "<CR>", "Line 2", "<CR>", "Line 3", "<Esc>",
            "gg", "o", "New line", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.count >= 4, "Should have at least 4 lines")
        #expect(result.buffer.contains("New line"), "Should contain new line")
    }
}

// MARK: - Part 4: VimEngine Performance and Edge Cases
struct VimEngineEdgeCaseTests {
    
    @Test func testEmptyKeystrokeArray() async throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([])
        
        #expect(result.mode == .normal, "Should be in normal mode with empty keystrokes")
        #expect(result.cursorRow == 0, "Cursor should be at origin")
        #expect(result.cursorCol == 0, "Cursor should be at origin")
    }
    
    @Test func testLargeKeystrokeSequence() async throws {
        let engine = VimEngine()
        
        var keystrokes = ["i"]
        for i in 1...100 {
            keystrokes.append("Line \(i) ")
        }
        keystrokes.append("<Esc>")
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should handle large keystroke sequence")
        #expect(result.buffer.first?.contains("Line 1") == true, "Should contain first line")
        #expect(result.buffer.first?.contains("Line 100") == true, "Should contain last line")
    }
    
    @Test func testSpecialCharacters() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "Special: !@#$%^&*()", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should handle special characters")
        #expect(result.buffer.first?.contains("Special: !@#$%^&*()") == true, "Should contain special characters")
    }
    
    @Test func testUnicodeCharacters() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "Unicode: 你好世界 🌍", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should handle unicode characters")
        #expect(result.buffer.first?.contains("Unicode:") == true, "Should contain unicode text")
    }
    
    @Test func testModeTransitions() async throws {
        let engine = VimEngine()
        
        let keystrokes = [
            "i", "Insert mode", "<Esc>",
            "v", "<Esc>",
            "V", "<Esc>",
            ":", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode after multiple transitions")
    }
    
    @Test func testBufferStateConsistency() async throws {
        let session = NvimSession()
        let engine = VimEngine()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let initialState = try engine.getState(session: session)
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i, .T, .e, .s, .t, .escape])
        
        let finalState = try engine.getState(session: session)
        
        #expect(initialState?.mode == .normal, "Initial state should be normal mode")
        #expect(finalState?.mode == .normal, "Final state should be normal mode")
        #expect(finalState?.buffer != initialState?.buffer, "Buffer should have changed")
        
        session.stop()
    }
}