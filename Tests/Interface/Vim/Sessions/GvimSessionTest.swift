/*
Author: <Chuanyu> (skewcy@gmail.com)
GvimSessionTest.swift (c) 2025
Desc: Comprehensive tests for GvimSession functionality
Created:  2025-08-21T22:20:13.443Z
*/

import Testing
import Foundation
@testable import VimCafe

// MARK: - Part 1: GvimSession Basic Functionality Tests
struct GvimSessionBasicTests {
    
    @Test func testGvimSessionStartStop() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        let isRunningAfterCreation = await session.isRunning()
        let isRunningAfterStart = await session.isRunning()
        #expect(isRunningAfterCreation, "Session should be running after creation")
        #expect(isRunningAfterStart, "Session should be running after start")
        
        try await session.stop()
        let isRunningAfterStop = await session.isRunning()
        #expect(!isRunningAfterStop, "Session should not be running after stop")
    }
    
    @Test func testGvimSessionGetMode() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try await session.getMode()
        #expect(mode.mode == "n", "Should start in normal mode")
        #expect(!mode.blocking, "Should not be blocking initially")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionSendInput() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        try await session.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))
        
        let mode = try await session.getMode()
        #expect(mode.mode == "i", "Should be in insert mode after 'i' command")
        
        try await session.sendInput("\u{1b}")
        try await Task.sleep(for: .milliseconds(100))
        
        let normalMode = try await session.getMode()
        #expect(normalMode.mode == "n", "Should return to normal mode after escape")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionBufferOperations() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        let testLines = ["First line", "Second line", "Third line"]
        try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await Task.sleep(for: .milliseconds(100))
        
        let retrievedLines = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(retrievedLines == testLines, "Retrieved lines should match set lines")
        
        let singleLine = ["Modified line"]
        try await session.setBufferLines(buffer: 1, start: 0, end: 1, lines: singleLine)
        try await Task.sleep(for: .milliseconds(100))
        
        let modifiedLines = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(modifiedLines[0] == "Modified line", "First line should be modified")
        #expect(modifiedLines.count >= 1, "Should have at least one line")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionCursorOperations() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        let testLines = ["Line 1", "Line 2", "Line 3"]
        try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await Task.sleep(for: .milliseconds(100))
        
        try await session.setCursorPosition(window: 0, row: 1, col: 3)
        try await Task.sleep(for: .milliseconds(100))
        
        let position = try await session.getCursorPosition(window: 0)
        #expect(position.row == 1, "Cursor row should be 1")
        #expect(position.col == 3, "Cursor col should be 3")
        
        try await session.setCursorPosition(window: 0, row: 2, col: 0)
        try await Task.sleep(for: .milliseconds(100))
        
        let newPosition = try await session.getCursorPosition(window: 0)
        #expect(newPosition.row == 2, "Cursor row should be 2")
        #expect(newPosition.col == 0, "Cursor col should be 0")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionEmptyBuffer() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        let initialLines = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(initialLines.count >= 0, "Initial buffer should be valid")
        
        let emptyLines: [String] = []
        try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: emptyLines)
        try await Task.sleep(for: .milliseconds(100))
        
        let resultLines = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(resultLines.count <= 1, "Empty buffer should have at most one empty line")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionTimeout() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try await session.getMode()
        #expect(mode.mode == "n", "Should respond within timeout")
        
        try await session.stop()
    }

    @Test func testGvimSessionMode() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        try await session.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))

        let insertMode = try await session.getMode()
        #expect(insertMode.mode == "i", "Should be in insert mode after 'i' command")

        try await session.sendInput("<Esc>")
        try await Task.sleep(for: .milliseconds(100))

        let normalMode = try await session.getMode()
        #expect(normalMode.mode == "n", "Should return to normal mode after escape")

        try await session.sendInput("r")
        try await Task.sleep(for: .milliseconds(100))

        let replaceMode = try await session.getMode()
        #expect(replaceMode.mode == "R", "Should be in replace mode after 'R' command")

        try await session.sendInput("<Esc>")
        try await session.sendInput("<C-V>")
        try await Task.sleep(for: .milliseconds(100))

        let visualMode = try await session.getMode()
        #expect(visualMode.mode == "v", "Should be in visual mode after '<C-V>' command")

        try await session.sendInput("<Esc>")
        try await Task.sleep(for: .milliseconds(100))

        let normalMode2 = try await session.getMode()
        #expect(normalMode2.mode == "n", "Should return to normal mode after escape")

        try await session.stop()
    }
}

// MARK: - Part 2: Multiple GvimSession Tests
struct GvimSessionMultipleInstanceTests {
    
    @Test func testMultipleSessionsIndependence() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        
        try await Task.sleep(for: .milliseconds(300))
        
        #expect(await session1.isRunning(), "Session 1 should be running")
        #expect(await session2.isRunning(), "Session 2 should be running")
        
        let lines1 = ["Session 1 content", "Line 2 for session 1"]
        let lines2 = ["Session 2 content", "Line 2 for session 2", "Line 3 for session 2"]
        
        try await session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines1)
        try await session2.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines2)
        
        try await Task.sleep(for: .milliseconds(200))
        
        let retrieved1 = try await session1.getBufferLines(buffer: 1, start: 0, end: -1)
        let retrieved2 = try await session2.getBufferLines(buffer: 1, start: 0, end: -1)
        
        #expect(retrieved1 == lines1, "Session 1 content should be independent")
        #expect(retrieved2 == lines2, "Session 2 content should be independent")
        #expect(retrieved1 != retrieved2, "Sessions should have different content")
        
        try await session1.stop()
        try await session2.stop()
    }
    
    @Test func testMultipleSessionsCursorIndependence() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        
        try await Task.sleep(for: .milliseconds(300))
        
        let testLines = ["Line 1", "Line 2", "Line 3", "Line 4"]
        try await session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await session2.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        
        try await Task.sleep(for: .milliseconds(200))
        
        try await session1.setCursorPosition(window: 0, row: 1, col: 2)
        try await session2.setCursorPosition(window: 0, row: 3, col: 1)
        
        try await Task.sleep(for: .milliseconds(200))
        
        let pos1 = try await session1.getCursorPosition(window: 0)
        let pos2 = try await session2.getCursorPosition(window: 0)
        
        #expect(pos1.row == 1, "Session 1 cursor row should be 1")
        #expect(pos1.col == 2, "Session 1 cursor col should be 2")
        #expect(pos2.row == 3, "Session 2 cursor row should be 3")
        #expect(pos2.col == 1, "Session 2 cursor col should be 1")
        
        try await session1.stop()
        try await session2.stop()
    }
    
    @Test func testMultipleSessionsModeIndependence() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        
        try await Task.sleep(for: .milliseconds(300))
        
        try await session1.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))
        
        let mode1 = try await session1.getMode()
        let mode2 = try await session2.getMode()
        
        #expect(mode1.mode == "i", "Session 1 should be in insert mode")
        #expect(mode2.mode == "n", "Session 2 should remain in normal mode")
        
        try await session1.sendInput("\u{1b}")
        try await Task.sleep(for: .milliseconds(100))
        
        let finalMode1 = try await session1.getMode()
        let finalMode2 = try await session2.getMode()
        
        #expect(finalMode1.mode == "n", "Session 1 should return to normal mode")
        #expect(finalMode2.mode == "n", "Session 2 should still be in normal mode")

        try await session1.stop()
        try await session2.stop()
    }
    
    @Test func testSessionCreationAfterOthersRunning() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        try await Task.sleep(for: .milliseconds(200))
        
        let testContent = ["Existing session content"]
        try await session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testContent)
        try await Task.sleep(for: .milliseconds(100))
        
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(await session1.isRunning(), "Original session should still be running")
        #expect(await session2.isRunning(), "New session should be running")
        
        let lines1 = try await session1.getBufferLines(buffer: 1, start: 0, end: -1)
        let lines2 = try await session2.getBufferLines(buffer: 1, start: 0, end: -1)
        
        #expect(lines1 == testContent, "Original session content should be preserved")
        #expect(lines2 != lines1, "New session should have different content")
        
        try await session1.stop()
        try await session2.stop()
    }
    
    @Test func testStoppingOneSessionDoesNotAffectOthers() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session3 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        
        try await Task.sleep(for: .milliseconds(400))
        
        #expect(await session1.isRunning(), "Session 1 should be running")
        #expect(await session2.isRunning(), "Session 2 should be running")
        #expect(await session3.isRunning(), "Session 3 should be running")
        
        try await session2.stop()
        
        let session1Running = await session1.isRunning()
        let session2Running = await session2.isRunning()
        let session3Running = await session3.isRunning()
        #expect(session1Running, "Session 1 should still be running")
        #expect(!session2Running, "Session 2 should be stopped")
        #expect(session3Running, "Session 3 should still be running")
        
        let mode1 = try await session1.getMode()
        let mode3 = try await session3.getMode()
        
        #expect(mode1.mode == "n", "Session 1 should still work")
        #expect(mode3.mode == "n", "Session 3 should still work")
        
        try await session1.stop()
        try await session3.stop()
    }
    
    @Test func testMultipleSessionsStressTest() async throws {
        var sessions: [any SessionProtocol] = []
        for _ in 0..<5 {
            let session = try await SessionManager.shared.createAndStartSession(type: .vim)
            sessions.append(session)
        }
        
        try await Task.sleep(for: .milliseconds(500))
        
        for (index, session) in sessions.enumerated() {
            #expect(await session.isRunning(), "Session \(index) should be running")
            
            let content = ["Session \(index) line 1", "Session \(index) line 2"]
            try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: content)
        }
        
        try await Task.sleep(for: .milliseconds(300))
        
        for (index, session) in sessions.enumerated() {
            let lines = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
            #expect(lines.contains("Session \(index) line 1"), "Session \(index) should have its own content")
        }
        
        for session in sessions {
            try await session.stop()
        }
        
        for session in sessions {
            let isRunning = await session.isRunning()
            #expect(!isRunning, "All sessions should be stopped")
        }
    }
}

// MARK: - Part 3: GvimSession Specific Features Tests
struct GvimSessionSpecificTests {
    
    @Test func testGvimSessionWithCustomGvimPath() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        #expect(await session.isRunning(), "Session should be running after creation")
    }
    
    @Test func testGvimSessionVimscriptExecution() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        // Test that we can execute Vimscript commands through the session
        try await session.sendInput(":echo 'test'")
        try await session.sendInput("<CR>")
        try await Task.sleep(for: .milliseconds(100))
        
        // Should still be in normal mode after command
        let mode = try await session.getMode()
        #expect(mode.mode == "n", "Should return to normal mode after command")
        
        try await session.stop()
    }
    
    @Test func testGvimSessionErrorHandling() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        
        // Test that invalid buffer operations throw appropriate errors
        do {
            _ = try await session.getBufferLines(buffer: 999, start: 0, end: -1)
            Issue.record("Should have thrown an error for invalid buffer")
        } catch {
            // Expected to throw an error
        }
        
        try await session.stop()
    }
    
    @Test func testGvimSessionServerNameUniqueness() async throws {
        let session1 = try await SessionManager.shared.createAndStartSession(type: .vim)
        let session2 = try await SessionManager.shared.createAndStartSession(type: .vim)
        
        // Sessions with different server names should be independent
        #expect(await session1.isRunning(), "Session 1 should be running after creation")
        #expect(await session2.isRunning(), "Session 2 should be running after creation")
    }
}

// MARK: - Part 4: GvimSession Performance Tests
struct GvimSessionPerformanceTests {
    @Test func createSessionTime() async throws {
        let startTime = Date()
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Session creation time: \(duration) seconds")
        try await session.stop()
    }

    @Test func stopSessionTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        let startTime = Date()
        try await session.stop()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Session stop time: \(duration) seconds")
    }

    @Test func sendInputTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        let startTime = Date()
        try await session.sendInput("i")
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Send input time: \(duration) seconds")
        try await session.stop()
    }

    @Test func getModeTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        let startTime = Date()
        let _ = try await session.getMode()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get mode time: \(duration) seconds")
        try await session.stop()
    }

    @Test func getBufferLinesTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        let startTime = Date()
        let _ = try await session.getBufferLines(buffer: 1, start: 0, end: -1)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get buffer lines time: \(duration) seconds")
        try await session.stop()
    }

    @Test func getCursorPositionTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        let startTime = Date()
        let _ = try await session.getCursorPosition(window: 0)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get cursor position time: \(duration) seconds")
        try await session.stop()
    }

    @Test func setBufferLinesTime() async throws {
        let session = try await SessionManager.shared.createAndStartSession(type: .vim)
        try await Task.sleep(for: .milliseconds(200))
        let startTime = Date()
        let lines = ["Line 1", "Line 2", "Line 3"]
        try await session.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Set buffer lines time: \(duration) seconds")
        try await session.stop()
    }
}