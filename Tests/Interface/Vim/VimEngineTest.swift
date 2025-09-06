/*
Author: <Chuanyu> (skewcy@gmail.com)
VimEngineTest.swift (c) 2025
Desc: Comprehensive tests for VimEngine functionality with real nvim integration
Created:  2025-08-20T00:00:00.000Z
*/

import Testing
import Foundation
@testable import VimCafe

private let sessionType = SessionType.nvim

// MARK: - Part 1: VimEngine Basic Functionality Tests
struct VimEngineBasicTests {
    
    @Test func testSingleKeystrokeExecution() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.i])
        
        #expect(result.mode == .insert, "Should be in insert mode after 'i' keystroke")
        #expect(result.cursor.row >= 0, "Cursor row should be valid")
        #expect(result.cursor.col >= 0, "Cursor col should be valid")
    }
    
    @Test func testNavigationKeystrokes() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.i, .H, .e, .l, .l, .o, .escape, .h])
        
        #expect(result.mode == .normal, "Should be in normal mode after escape")
        #expect(result.buffer.contains("Hello"), "Buffer should contain typed text")
        #expect(result.cursor.col < 5, "Cursor should move left after 'h' command")
    }
    
    @Test func testInsertModeTextEntry() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.i, .H, .e, .l, .l, .o, .space, .W, .o, .r, .l, .d, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode after escape")
        #expect(result.buffer.first?.contains("Hello World") == true, "Buffer should contain inserted text")
    }
    
    @Test func testMultilineTextEntry() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.i, .L, .i, .n, .e, .space, .one, .enter, .L, .i, .n, .e, .space, .two, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.count >= 2, "Should have at least 2 lines")
        #expect(result.buffer.contains("Line 1"), "Should contain first line")
        #expect(result.buffer.contains("Line 2"), "Should contain second line")
    }
    
    @Test func testMovementBetweenLines() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.i, .F, .i, .r, .s, .t, .enter, .S, .e, .c, .o, .n, .d, .enter, .T, .h, .i, .r, .d, .escape, .k, .k])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.cursor.row == 0, "Should be on first line after two 'k' movements")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
    }
}

// MARK: - Part 2: VimEngine Session Integration Tests
struct VimEngineSessionTests {
    
    @Test func testVimEngineWithExistingSession() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        let engine = VimEngine(defaultSessionType: sessionType)
        try await Task.sleep(for: .milliseconds(200))
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i, .T, .e, .s, .t, .space, .w, .i, .t, .h, .space, .s, .e, .s, .s, .i, .o, .n, .escape])
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.first?.contains("Test with session") == true, "Should contain text")
        
        try await session.stop()
    }
    
    @Test func testVimEngineStateRetrieval() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        let engine = VimEngine(defaultSessionType: sessionType)
        try await Task.sleep(for: .milliseconds(200))
        
        try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: ["Test line 1", "Test line 2"])
        try await session.setCursorPosition(window: 0, row: 1, col: 5)
        
        let state = try await engine.getState(session: session)
        
        #expect(state != nil, "Should retrieve state successfully")
        #expect(state?.buffer == ["Test line 1", "Test line 2"], "Should match buffer content")
        #expect(state?.cursor.row == 1, "Should match cursor row")
        #expect(state?.cursor.col == 5, "Should match cursor col")
        #expect(state?.mode == VimMode.normal, "Should be in normal mode")
        
        try await session.stop()
    }
    
    @Test func testVimEngineWithBlockingSession() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        let engine = VimEngine(defaultSessionType: sessionType)
        try await Task.sleep(for: .milliseconds(200))
        
        try await session.sendInput(":")
        try await Task.sleep(for: .milliseconds(100))
        
        let state = try await engine.getState(session: session)
        
        if let state = state {
            #expect(state.mode == VimMode.command, "Should be in command mode when not blocking")
        }
        
        try await session.sendInput("<Esc>")
        try await session.stop()
    }
    
    @Test func testVimEngineErrorHandling() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        #expect(await session.isRunning(), "Session should be running after creation")
    }
}

// MARK: - Part 3: VimEngine Complex Editing Tests
struct VimEngineEditingTests {
    
    @Test func testComplexEditingSequence() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let keystrokes: [VimKeystroke] = [
            .i, .f, .u, .n, .c, .t, .i, .o, .n, .space, .h, .e, .l, .l, .o, .leftParen, .rightParen, .space, .leftBrace, .enter,
            .space, .space, .space, .space, .c, .o, .n, .s, .o, .l, .e, .period, .l, .o, .g, .leftParen, .quote, .H, .e, .l, .l, .o, .space, .W, .o, .r, .l, .d, .quote, .rightParen, .semicolon, .enter,
            .rightBrace, .escape,
            .g, .g, .A, .space, .slash, .slash, .space, .F, .u, .n, .c, .t, .i, .o, .n, .space, .d, .e, .c, .l, .a, .r, .a, .t, .i, .o, .n, .escape
        ]
        
        let result = try await engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode")
        #expect(result.buffer.count >= 3, "Should have multiple lines")
        #expect(result.buffer.first?.contains("function hello()") == true, "Should contain function declaration")
        #expect(result.buffer.first?.contains("// Function declaration") == true, "Should contain comment")
    }
    
    @Test func testVisualModeSelection() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let keystrokes: [VimKeystroke] = [
            .i, .S, .e, .l, .e, .c, .t, .space, .t, .h, .i, .s, .space, .t, .e, .x, .t, .escape,
            .zero, .v, .e
        ]
        
        let result = try await engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .visual, "Should be in visual mode")
        #expect(result.buffer.first?.contains("Select this text") == true, "Should contain text")
    }
    
    @Test func testDeleteAndUndoOperations() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Text to delete")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.d, .w])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode")
        #expect(result.buffer.first?.contains("Text") == false, "First word should be deleted")
        #expect(result.buffer.first?.contains("to delete") == true, "Rest of text should remain")
    }
    
    @Test func testSearchAndReplace() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("foo bar foo")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.slash])
        try await session.sendInput("foo")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        
        #expect(result.mode == VimMode.normal, "Should return to normal mode after search")
        #expect(result.buffer.first?.contains("foo bar foo") == true, "Should contain original text")
    }
    
    @Test func testWordMovement() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("word1 word2 word3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode")
        #expect(result.cursor.col >= 12, "Cursor should be on third word")
    }
    
    @Test func testLineOperations() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Line 1")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Line 2")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Line 3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        try await session.sendInput("New line")
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode")
        #expect(result.buffer.count >= 4, "Should have at least 4 lines")
        #expect(result.buffer.contains("New line"), "Should contain new line")
    }
}

// MARK: - Part 4: VimEngine Performance and Edge Cases
struct VimEngineEdgeCaseTests {
    
    @Test func testEmptyKeystrokeArray() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode with empty keystrokes")
        #expect(result.cursor.row == 0, "Cursor should be at origin")
        #expect(result.cursor.col == 0, "Cursor should be at origin")
    }
    
    @Test func testLargeKeystrokeSequence() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        for i in 1...100 {
            try await session.sendInput("Line \(i) ")
        }
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should handle large keystroke sequence")
        #expect(result.buffer.first?.contains("Line 1") == true, "Should contain first line")
        #expect(result.buffer.first?.contains("Line 100") == true, "Should contain last line")
    }

    @Test func testSearchSequence() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime

        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape, .zero])

        let result = try await engine.execKeystrokes(session: session, keystrokes: [.f, .l, .f, .l, .f, .period, .f, .escape])

        #expect(result.cursor.col == 3, "Should move to second 'l'")
        #expect(result.mode == VimMode.normal, "Should remain in normal mode")
    }

    @Test func testSpecialCharacters() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Special: !@#$%^&*()")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should handle special characters")
        #expect(result.buffer.first?.contains("Special: !@#$%^&*()") == true, "Should contain special characters")
    }
    
    @Test func testUnicodeCharacters() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Unicode: 你好世界 🌍")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should handle unicode characters")
        #expect(result.buffer.first?.contains("Unicode:") == true, "Should contain unicode text")
    }
    
    @Test func testModeTransitions() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Insert mode")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.v])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.V])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode after multiple transitions")
    }
    
    @Test func testBufferStateConsistency() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        let engine = VimEngine(defaultSessionType: sessionType)
        try await Task.sleep(for: .milliseconds(200))
        
        let initialState = try await engine.getState(session: session)
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i, .T, .e, .s, .t, .escape])
        
        let finalState = try await engine.getState(session: session)
        
        #expect(initialState?.mode == .normal, "Initial state should be normal mode")
        #expect(finalState?.mode == .normal, "Final state should be normal mode")
        #expect(finalState?.buffer != initialState?.buffer, "Buffer should have changed")
        
        try await session.stop()
    }

    @Test func testCopyPaste() async throws {
        let defaultState = VimState(buffer: ["abc123abc123"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        let engine = VimEngine(defaultState: defaultState, defaultSessionType: sessionType)

        try await Task.sleep(for: .milliseconds(200))
        let state = try await engine.execKeystrokes(decodeKeystrokes("dt1$p"))
        #expect(state.buffer == ["123abc123abc"], "Should contain pasted text")
        #expect(state.mode == VimMode.normal, "Should be in normal mode")
    }
}

// MARK: - Part 5: Normal Mode Motion Tests
struct VimEngineMotionTests {
    
    // MARK: - Basic Direction Tests
    @Test func testMoveLeftBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.h])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 4, "Should move left by one column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveLeftAtBeginning() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.h])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 0, "Should not move past beginning")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveRightBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 6, "Should move right by one column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveRightAtEnd() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 4, "Should not move past end")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveDownBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        
        #expect(result.cursor.row == 1, "Should move down by one row")
        #expect(result.cursor.col == 2, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveDownAtBottom() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        
        #expect(result.cursor.row == 1, "Should not move past bottom")
        #expect(result.cursor.col == 2, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveUpBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.k])
        
        #expect(result.cursor.row == 0, "Should move up by one row")
        #expect(result.cursor.col == 2, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveUpAtTop() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.k])
        
        #expect(result.cursor.row == 0, "Should not move past top")
        #expect(result.cursor.col == 2, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    // MARK: - Counted Motion Tests
    @Test func testMoveDownWithCountBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3\nline4\nline5")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.three, .j])
        
        #expect(result.cursor.row == 3, "Should move down 3 rows")
        #expect(result.cursor.col == 0, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveDownWithCountOverflow() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.five, .j])
        
        #expect(result.cursor.row == 2, "Should stop at last line")
        #expect(result.cursor.col == 0, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveUpWithCountBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3\nline4\nline5")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 4, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.three, .k])
        
        #expect(result.cursor.row == 1, "Should move up 3 rows")
        #expect(result.cursor.col == 0, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testMoveUpWithCountOverflow() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 2, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.five, .k])
        
        #expect(result.cursor.row == 0, "Should stop at first line")
        #expect(result.cursor.col == 0, "Should maintain column position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    // MARK: - Word Motion Tests
    @Test func testWordForwardBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 6, "Should move to start of next word")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testWordForwardMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world\ntest case")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 6)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        
        #expect(result.cursor.row == 1, "Should move to next line")
        #expect(result.cursor.col == 0, "Should move to start of next word")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testWordBackwardBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 10)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.b])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 6, "Should move to start of previous word")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testWordEndBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.e])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 4, "Should move to end of current word")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    // MARK: - Line Motion Tests
    @Test func testStartOfLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 0, "Should move to start of line")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testFirstNonBlankBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("  hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.caret])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 2, "Should move to first non-blank character")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testEndOfLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.dollar])
        
        #expect(result.cursor.row == 0, "Should remain on same row")
        #expect(result.cursor.col == 10, "Should move to end of line")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    // MARK: - File Motion Tests
    @Test func testGoToFirstLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 2, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        
        #expect(result.cursor.row == 0, "Should move to first line")
        #expect(result.cursor.col == 0, "Should move to first column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testGoToLastLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.G])
        
        #expect(result.cursor.row == 2, "Should move to last line")
        #expect(result.cursor.col == 0, "Should move to first column of last line")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testGoToLineNumberBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3\nline4\nline5")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.three, .g, .g])
        
        #expect(result.cursor.row == 2, "Should move to line 3 (0-indexed)")
        #expect(result.cursor.col == 0, "Should move to first column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testGoToLineNumberWithG() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3\nline4\nline5")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.three, .G])
        
        #expect(result.cursor.row == 2, "Should move to line 3 (0-indexed)")
        #expect(result.cursor.col == 0, "Should move to first column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testGoToLineNumberBeyondEnd() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.one, .zero, .g, .g])
        
        #expect(result.cursor.row == 2, "Should move to last line when target exceeds buffer")
        #expect(result.cursor.col == 0, "Should move to first column")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
}

// MARK: - Part 6: Normal Mode Operator Tests
struct VimEngineOperatorTests {
    
    // MARK: - Insert Mode Tests
    @Test func testInsertAtCursorBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 5, "Cursor col should match")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtCursorEmptyLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should be 0")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtCursorEndOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        #expect(result.buffer == ["test"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 3, "Cursor col should match")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtCursorMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        #expect(result.buffer == ["line1", "line2", "line3"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should match")
        #expect(result.cursor.col == 2, "Cursor col should match")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtCursorBeginningOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 0, "Cursor col should match")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    // MARK: - Append Mode Tests
    @Test func testAppendAfterCursorBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 3, "Cursor should move right by one")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAfterCursorEndOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        
        #expect(result.buffer == ["test"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 4, "Cursor should move to end of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAfterCursorEmptyLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should remain 0")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAfterCursorMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("first\nsecond\nthird")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        
        #expect(result.buffer == ["first", "second", "third"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should match")
        #expect(result.cursor.col == 4, "Cursor should move right by one")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAfterCursorBeginningOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 1, "Cursor should move right by one")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    // MARK: - Insert at Beginning of Line Tests
    @Test func testInsertAtBeginningOfLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 0, "Cursor should move to beginning of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtBeginningOfLineWithWhitespace() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("  hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        
        #expect(result.buffer == ["  hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 2, "Cursor should move to first non-whitespace character")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtBeginningOfLineEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should be 0")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtBeginningOfLineMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        
        #expect(result.buffer == ["line1", "line2", "line3"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should match")
        #expect(result.cursor.col == 0, "Cursor should move to beginning of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testInsertAtBeginningOfLineSingleChar() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("x")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        
        #expect(result.buffer == ["x"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    // MARK: - Append at End of Line Tests
    @Test func testAppendAtEndOfLineBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 11, "Cursor should move to end of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAtEndOfLineSingleChar() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("x")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        
        #expect(result.buffer == ["x"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 1, "Cursor should move to end")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAtEndOfLineEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should be 0")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAtEndOfLineMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("first\nsecond\nthird")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        
        #expect(result.buffer == ["first", "second", "third"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should match")
        #expect(result.cursor.col == 6, "Cursor should move to end of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testAppendAtEndOfLineWithTrailingSpace() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello ")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        
        #expect(result.buffer == ["hello "], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should match")
        #expect(result.cursor.col == 6, "Cursor should move to end of line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    // MARK: - Open Line Tests
    @Test func testOpenLineBelowBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        
        #expect(result.buffer == ["hello world", ""], "Should add new line below")
        #expect(result.cursor.row == 1, "Cursor should move to new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning of new line")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineBelowEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        
        #expect(result.buffer == ["", ""], "Should add new line below empty line")
        #expect(result.cursor.row == 1, "Cursor should move to new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineBelowMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        
        #expect(result.buffer == ["line1", "line2", "", "line3"], "Should add new line below current line")
        #expect(result.cursor.row == 2, "Cursor should move to new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineBelowLastLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        
        #expect(result.buffer == ["line1", "line2", ""], "Should add new line below last line")
        #expect(result.cursor.row == 2, "Cursor should move to new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineBelowSingleChar() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("x")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        
        #expect(result.buffer == ["x", ""], "Should add new line below")
        #expect(result.cursor.row == 1, "Cursor should move to new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineAboveBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.O])
        
        #expect(result.buffer == ["", "hello world"], "Should add new line above")
        #expect(result.cursor.row == 0, "Cursor should be on new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineAboveEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.O])
        
        #expect(result.buffer == ["", ""], "Should add new line above empty line")
        #expect(result.cursor.row == 0, "Cursor should be on new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineAboveMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.O])
        
        #expect(result.buffer == ["line1", "", "line2", "line3"], "Should add new line above current line")
        #expect(result.cursor.row == 1, "Cursor should be on new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineAboveFirstLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.O])
        
        #expect(result.buffer == ["", "line1", "line2"], "Should add new line above first line")
        #expect(result.cursor.row == 0, "Cursor should be on new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    @Test func testOpenLineAboveSingleChar() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("x")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.O])
        
        #expect(result.buffer == ["", "x"], "Should add new line above")
        #expect(result.cursor.row == 0, "Cursor should be on new line")
        #expect(result.cursor.col == 0, "Cursor should be at beginning")
        #expect(result.mode == .insert, "Should be in insert mode")
    }
    
    // MARK: - Command Mode Tests
    @Test func testEnterCommandModeBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 5, "Cursor col should remain same")
        #expect(result.mode == .command, "Should be in command mode")
    }
    
    @Test func testEnterCommandModeEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should be 0")
        #expect(result.mode == .command, "Should be in command mode")
    }
    
    @Test func testEnterCommandModeMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        
        #expect(result.buffer == ["line1", "line2", "line3"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should remain same")
        #expect(result.cursor.col == 2, "Cursor col should remain same")
        #expect(result.mode == .command, "Should be in command mode")
    }
    
    @Test func testEnterCommandModeEndOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 4, "Cursor col should remain same")
        #expect(result.mode == .command, "Should be in command mode")
    }
    
    @Test func testEnterCommandModeBeginningOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 0, "Cursor col should remain same")
        #expect(result.mode == .command, "Should be in command mode")
    }
    
    // MARK: - Replace Tests
    @Test func testReplaceSingleCharBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.r])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == ["helloxworld"], "Character should be replaced")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 5, "Cursor col should remain same")
        #expect(result.mode == .normal, "Should return to normal mode")
    }
    
    @Test func testReplaceSingleCharWithSpace() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 2)
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.r])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.space])
        
        #expect(result.buffer == ["he lo"], "Character should be replaced with space")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 2, "Cursor col should remain same")
        #expect(result.mode == .normal, "Should return to normal mode")
    }
    
    @Test func testReplaceSingleCharAtEnd() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.r])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.exclamation])
        
        #expect(result.buffer == ["hell!"], "Last character should be replaced")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 4, "Cursor col should remain same")
        #expect(result.mode == VimMode.normal, "Should return to normal mode")
    }
    
    @Test func testReplaceSingleCharMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.r])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.X])
        
        #expect(result.buffer == ["line1", "liXe2", "line3"], "Character should be replaced in multiline")
        #expect(result.cursor.row == 1, "Cursor row should remain same")
        #expect(result.cursor.col == 2, "Cursor col should remain same")
        #expect(result.mode == .normal, "Should return to normal mode")
    }
    
    @Test func testReplaceSingleCharWithNumber() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 1)
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.r])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.five])
        
        #expect(result.buffer == ["t5st"], "Character should be replaced with number")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 1, "Cursor col should remain same")
        #expect(result.mode == .normal, "Should return to normal mode")
    }
    
    // MARK: - Replace Mode Tests
    @Test func testEnterReplaceModeBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        
        #expect(result.buffer == ["hello world"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 5, "Cursor col should remain same")
        #expect(result.mode == .replace, "Should be in replace mode")
    }
    
    @Test func testEnterReplaceModeEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        
        #expect(result.buffer == [""], "Buffer should be empty")
        #expect(result.cursor.row == 0, "Cursor row should be 0")
        #expect(result.cursor.col == 0, "Cursor col should be 0")
        #expect(result.mode == .replace, "Should be in replace mode")
    }
    
    @Test func testEnterReplaceModeMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        
        #expect(result.buffer == ["line1", "line2", "line3"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 1, "Cursor row should remain same")
        #expect(result.cursor.col == 2, "Cursor col should remain same")
        #expect(result.mode == .replace, "Should be in replace mode")
    }
    
    @Test func testEnterReplaceModeEndOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 4, "Cursor col should remain same")
        #expect(result.mode == .replace, "Should be in replace mode")
    }
    
    @Test func testEnterReplaceModeBeginningOfLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 0)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        
        #expect(result.buffer == ["hello"], "Buffer should remain unchanged")
        #expect(result.cursor.row == 0, "Cursor row should remain same")
        #expect(result.cursor.col == 0, "Cursor col should remain same")
        #expect(result.mode == .replace, "Should be in replace mode")
    }
    
    // MARK: - Join Lines Tests
    @Test func testJoinLinesBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.J])
        
        #expect(result.buffer == ["hello world"], "Lines should be joined with space")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 5, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesMultiple() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.J])
        
        #expect(result.buffer == ["line1", "line2 line3"], "Should join current and next line")
        #expect(result.cursor.row == 1, "Cursor should remain on current line")
        #expect(result.cursor.col == 5, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithSpaces() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello \n world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.J])
        
        #expect(result.buffer == ["hello world"], "Should preserve existing spaces")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 6, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesEmptyLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\n\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.J])
        
        #expect(result.buffer == ["hello", "world"], "Should join with empty line")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 4, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesLastLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.J])
        
        #expect(result.buffer == ["hello", "world"], "Should not join when on last line")
        #expect(result.cursor.row == 1, "Cursor should remain on last line")
        #expect(result.cursor.col == 4, "Cursor should remain at end")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithoutSpaceBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .J])
        
        #expect(result.buffer == ["helloworld"], "Lines should be joined without space")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 5, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithoutSpaceMultiple() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .J])
        
        #expect(result.buffer == ["line1", "line2line3"], "Should join without space")
        #expect(result.cursor.row == 1, "Cursor should remain on current line")
        #expect(result.cursor.col == 5, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithoutSpaceWithSpaces() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello \n world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .J])
        
        #expect(result.buffer == ["hello  world"], "Should preserve existing spaces")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 6, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithoutSpaceEmpty() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\n\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 3)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .J])
        
        #expect(result.buffer == ["hello", "world"], "Should join with empty line without space")
        #expect(result.cursor.row == 0, "Cursor should remain on first line")
        #expect(result.cursor.col == 5, "Cursor should be positioned after join")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testJoinLinesWithoutSpaceLastLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello\nworld")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.g, .J])
        
        #expect(result.buffer == ["hello", "world"], "Should not join when on last line")
        #expect(result.cursor.row == 1, "Cursor should remain on last line")
        #expect(result.cursor.col == 4, "Cursor should remain at end")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    // MARK: - Delete Character Tests
    @Test func testDeleteCharBasic() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello world")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 0, col: 5)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == ["helloworld"], "Character should be deleted")
        #expect(result.cursor.row == 0, "Cursor should remain on same row")
        #expect(result.cursor.col == 5, "Cursor should remain at same position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testDeleteCharAtEnd() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("hello")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == ["hell"], "Last character should be deleted")
        #expect(result.cursor.row == 0, "Cursor should remain on same row")
        #expect(result.cursor.col == 3, "Cursor should move left after delete")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testDeleteCharSingleChar() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("x")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == [""], "Single character should be deleted")
        #expect(result.cursor.row == 0, "Cursor should remain on same row")
        #expect(result.cursor.col == 0, "Cursor should move to beginning")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testDeleteCharMultiline() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line1\nline2\nline3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        try await session.setCursorPosition(window: 0, row: 1, col: 2)
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == ["line1", "li2", "line3"], "Character should be deleted in multiline")
        #expect(result.cursor.row == 1, "Cursor should remain on same row")
        #expect(result.cursor.col == 2, "Cursor should remain at same position")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }
    
    @Test func testDeleteCharEmptyLine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        try await session.start()
        // Session cleanup handled by runtime
        
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        
        #expect(result.buffer == [""], "Empty line should remain empty")
        #expect(result.cursor.row == 0, "Cursor should remain on same row")
        #expect(result.cursor.col == 0, "Cursor should remain at beginning")
        #expect(result.mode == .normal, "Should remain in normal mode")
    }

    @Test func testWqAndZZ() async throws {
        signal(SIGPIPE, SIG_IGN)
        let engine = VimEngine(defaultSessionType: .nvim)
        
        _ = try await engine.execKeystrokes([.w, .q, .j, .j])
        _ = try await engine.execKeystrokes([.Z, .Z, .g, .g])
    }
}   

extension VimKeystroke {
    static func random() -> VimKeystroke {
        return allowedKeys.randomElement()!
    }
}

struct VimEnginePerformanceTests {
    @Test func testExecKeystrokesTime() async throws {
        let engine = VimEngine(defaultSessionType: .nvim)
        
        // Randomly generate 100 keystrokes with length 20
        // And collect timing data for distribution analysis
        let length = 20
        let keystrokes = (0..<100).map { _ in
            var keystroke: [VimKeystroke] = []
            for _ in 0..<length {
                keystroke.append(VimKeystroke.random())
            }
            return keystroke
        }
        
        var keystrokeTimes: [Double] = []
        
        let startTime = Date()
        for keystroke in keystrokes {
            let keystrokeStartTime = Date()
            let _ = try await engine.execKeystrokes(keystroke)
            let keystrokeEndTime = Date()
            let keystrokeTime = keystrokeEndTime.timeIntervalSince(keystrokeStartTime)
            keystrokeTimes.append(keystrokeTime)
        }
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        
        // Calculate distribution statistics
        let sortedTimes = keystrokeTimes.sorted()
        let count = sortedTimes.count
        
        let minTime = sortedTimes.first ?? 0.0
        let minTimeKeystroke = keystrokes[keystrokeTimes.firstIndex(of: minTime)!]
        let maxTime = sortedTimes.last ?? 0.0
        let maxTimeKeystroke = keystrokes[keystrokeTimes.firstIndex(of: maxTime)!]
        let averageTime = keystrokeTimes.reduce(0.0, +) / Double(count)
        
        // Calculate quartiles
        let q1Index = count / 4
        let q3Index = (3 * count) / 4
        let q1Time = count > 0 ? sortedTimes[q1Index] : 0.0
        let q3Time = count > 0 ? sortedTimes[q3Index] : 0.0
        
        // Print distribution summary
        print("⏱️ Keystroke Timing Distribution Summary:")
        print("   Total keystrokes: \(count)")
        print("   Total duration: \(String(format: "%.4f", totalDuration)) seconds")
        print("   Min time: \(String(format: "%.4f", minTime)) seconds - \(encodeKeystrokes(minTimeKeystroke))")
        print("   Max time: \(String(format: "%.4f", maxTime)) seconds - \(encodeKeystrokes(maxTimeKeystroke))")
        print("   Average time: \(String(format: "%.4f", averageTime)) seconds")
        print("   1st Quartile (25%): \(String(format: "%.4f", q1Time)) seconds")
        print("   3rd Quartile (75%): \(String(format: "%.4f", q3Time)) seconds")
    }
}