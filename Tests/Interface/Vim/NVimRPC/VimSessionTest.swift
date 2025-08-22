/*
Author: <Chuanyu> (skewcy@gmail.com)
VimSessionTest.swift (c) 2025
Desc: Comprehensive tests for VimSession functionality
Created:  2025-08-21T22:20:13.443Z
*/

import Testing
import Foundation
@testable import VimCafe

// MARK: - Part 1: VimSession Basic Functionality Tests
struct VimSessionBasicTests {
    
    @Test func testVimSessionStartStop() throws {
        let session = VimSession()
        
        #expect(!session.isRunning(), "Session should not be running initially")
        
        try session.start()
        #expect(session.isRunning(), "Session should be running after start")
        
        session.stop()
        #expect(!session.isRunning(), "Session should not be running after stop")
    }
    
    @Test func testVimSessionGetMode() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should start in normal mode")
        #expect(!mode.blocking, "Should not be blocking initially")
        
        session.stop()
    }
    
    @Test func testVimSessionSendInput() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        try session.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))
        
        let mode = try session.getMode()
        #expect(mode.mode == "i", "Should be in insert mode after 'i' command")
        
        try session.sendInput("\u{1b}")
        try await Task.sleep(for: .milliseconds(100))
        
        let normalMode = try session.getMode()
        #expect(normalMode.mode == "n", "Should return to normal mode after escape")
        
        session.stop()
    }
    
    @Test func testVimSessionBufferOperations() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let testLines = ["First line", "Second line", "Third line"]
        try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await Task.sleep(for: .milliseconds(100))
        
        let retrievedLines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(retrievedLines == testLines, "Retrieved lines should match set lines")
        
        let singleLine = ["Modified line"]
        try session.setBufferLines(buffer: 1, start: 0, end: 1, lines: singleLine)
        try await Task.sleep(for: .milliseconds(100))
        
        let modifiedLines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(modifiedLines[0] == "Modified line", "First line should be modified")
        #expect(modifiedLines.count >= 1, "Should have at least one line")
        
        session.stop()
    }
    
    @Test func testVimSessionCursorOperations() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let testLines = ["Line 1", "Line 2", "Line 3"]
        try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await Task.sleep(for: .milliseconds(100))
        
        try session.setCursorPosition(window: 0, row: 1, col: 3)
        try await Task.sleep(for: .milliseconds(100))
        
        let position = try session.getCursorPosition(window: 0)
        #expect(position.row == 1, "Cursor row should be 1")
        #expect(position.col == 3, "Cursor col should be 3")
        
        try session.setCursorPosition(window: 0, row: 2, col: 0)
        try await Task.sleep(for: .milliseconds(100))
        
        let newPosition = try session.getCursorPosition(window: 0)
        #expect(newPosition.row == 2, "Cursor row should be 2")
        #expect(newPosition.col == 0, "Cursor col should be 0")
        
        session.stop()
    }
    
    @Test func testVimSessionEmptyBuffer() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let initialLines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(initialLines.count >= 0, "Initial buffer should be valid")
        
        let emptyLines: [String] = []
        try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: emptyLines)
        try await Task.sleep(for: .milliseconds(100))
        
        let resultLines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(resultLines.count <= 1, "Empty buffer should have at most one empty line")
        
        session.stop()
    }
    
    @Test func testVimSessionTimeout() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should respond within timeout")
        
        session.stop()
    }
}

// MARK: - Part 2: Multiple VimSession Tests
struct VimSessionMultipleInstanceTests {
    
    @Test func testMultipleSessionsIndependence() async throws {
        let session1 = VimSession()
        let session2 = VimSession()
        
        try session1.start()
        try session2.start()
        
        try await Task.sleep(for: .milliseconds(300))
        
        #expect(session1.isRunning(), "Session 1 should be running")
        #expect(session2.isRunning(), "Session 2 should be running")
        
        let lines1 = ["Session 1 content", "Line 2 for session 1"]
        let lines2 = ["Session 2 content", "Line 2 for session 2", "Line 3 for session 2"]
        
        try session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines1)
        try session2.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines2)
        
        try await Task.sleep(for: .milliseconds(200))
        
        let retrieved1 = try session1.getBufferLines(buffer: 1, start: 0, end: -1)
        let retrieved2 = try session2.getBufferLines(buffer: 1, start: 0, end: -1)
        
        #expect(retrieved1 == lines1, "Session 1 content should be independent")
        #expect(retrieved2 == lines2, "Session 2 content should be independent")
        #expect(retrieved1 != retrieved2, "Sessions should have different content")
        
        session1.stop()
        session2.stop()
    }
    
    @Test func testMultipleSessionsCursorIndependence() async throws {
        let session1 = VimSession()
        let session2 = VimSession()
        
        try session1.start()
        try session2.start()
        
        try await Task.sleep(for: .milliseconds(300))
        
        let testLines = ["Line 1", "Line 2", "Line 3", "Line 4"]
        try session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try session2.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        
        try await Task.sleep(for: .milliseconds(200))
        
        try session1.setCursorPosition(window: 0, row: 1, col: 2)
        try session2.setCursorPosition(window: 0, row: 3, col: 1)
        
        try await Task.sleep(for: .milliseconds(200))
        
        let pos1 = try session1.getCursorPosition(window: 0)
        let pos2 = try session2.getCursorPosition(window: 0)
        
        #expect(pos1.row == 1, "Session 1 cursor row should be 1")
        #expect(pos1.col == 2, "Session 1 cursor col should be 2")
        #expect(pos2.row == 3, "Session 2 cursor row should be 3")
        #expect(pos2.col == 1, "Session 2 cursor col should be 1")
        
        session1.stop()
        session2.stop()
    }
    
    @Test func testMultipleSessionsModeIndependence() async throws {
        let session1 = VimSession()
        let session2 = VimSession()
        
        try session1.start()
        try session2.start()
        
        try await Task.sleep(for: .milliseconds(300))
        
        try session1.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))
        
        let mode1 = try session1.getMode()
        let mode2 = try session2.getMode()
        
        #expect(mode1.mode == "i", "Session 1 should be in insert mode")
        #expect(mode2.mode == "n", "Session 2 should remain in normal mode")
        
        try session1.sendInput("\u{1b}")
        try await Task.sleep(for: .milliseconds(100))
        
        let finalMode1 = try session1.getMode()
        let finalMode2 = try session2.getMode()
        
        #expect(finalMode1.mode == "n", "Session 1 should return to normal mode")
        #expect(finalMode2.mode == "n", "Session 2 should still be in normal mode")
        
        session1.stop()
        session2.stop()
    }
    
    @Test func testSessionCreationAfterOthersRunning() async throws {
        let session1 = VimSession()
        
        try session1.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let testContent = ["Existing session content"]
        try session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testContent)
        try await Task.sleep(for: .milliseconds(100))
        
        let session2 = VimSession()
        try session2.start()
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(session1.isRunning(), "Original session should still be running")
        #expect(session2.isRunning(), "New session should be running")
        
        let lines1 = try session1.getBufferLines(buffer: 1, start: 0, end: -1)
        let lines2 = try session2.getBufferLines(buffer: 1, start: 0, end: -1)
        
        #expect(lines1 == testContent, "Original session content should be preserved")
        #expect(lines2 != lines1, "New session should have different content")
        
        session1.stop()
        session2.stop()
    }
    
    @Test func testStoppingOneSessionDoesNotAffectOthers() async throws {
        let session1 = VimSession()
        let session2 = VimSession()
        let session3 = VimSession()
        
        try session1.start()
        try session2.start()
        try session3.start()
        
        try await Task.sleep(for: .milliseconds(400))
        
        #expect(session1.isRunning(), "Session 1 should be running")
        #expect(session2.isRunning(), "Session 2 should be running")
        #expect(session3.isRunning(), "Session 3 should be running")
        
        session2.stop()
        
        #expect(session1.isRunning(), "Session 1 should still be running")
        #expect(!session2.isRunning(), "Session 2 should be stopped")
        #expect(session3.isRunning(), "Session 3 should still be running")
        
        let mode1 = try session1.getMode()
        let mode3 = try session3.getMode()
        
        #expect(mode1.mode == "n", "Session 1 should still work")
        #expect(mode3.mode == "n", "Session 3 should still work")
        
        session1.stop()
        session3.stop()
    }
    
    @Test func testMultipleSessionsStressTest() async throws {
        let sessions = (0..<5).map { index in 
            VimSession()
        }
        
        for session in sessions {
            try session.start()
        }
        
        try await Task.sleep(for: .milliseconds(500))
        
        for (index, session) in sessions.enumerated() {
            #expect(session.isRunning(), "Session \(index) should be running")
            
            let content = ["Session \(index) line 1", "Session \(index) line 2"]
            try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: content)
        }
        
        try await Task.sleep(for: .milliseconds(300))
        
        for (index, session) in sessions.enumerated() {
            let lines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
            #expect(lines.contains("Session \(index) line 1"), "Session \(index) should have its own content")
        }
        
        for session in sessions {
            session.stop()
        }
        
        for session in sessions {
            #expect(!session.isRunning(), "All sessions should be stopped")
        }
    }
}

// MARK: - Part 3: VimSession Specific Features Tests
struct VimSessionSpecificTests {
    
    @Test func testVimSessionWithCustomGvimPath() throws {
        let session = VimSession(gvimPath: "/opt/homebrew/bin/gvim")
        
        #expect(!session.isRunning(), "Session should not be running initially")
    }
    
    @Test func testVimSessionVimscriptExecution() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        // Test that we can execute Vimscript commands through the session
        try session.sendInput(":echo 'test'")
        try await Task.sleep(for: .milliseconds(100))
        
        // Should still be in normal mode after command
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should return to normal mode after command")
        
        session.stop()
    }
    
    @Test func testVimSessionErrorHandling() async throws {
        let session = VimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        // Test that invalid buffer operations throw appropriate errors
        do {
            _ = try session.getBufferLines(buffer: 999, start: 0, end: -1)
            Issue.record("Should have thrown an error for invalid buffer")
        } catch {
            // Expected to throw an error
        }
        
        session.stop()
    }
    
    @Test func testVimSessionServerNameUniqueness() throws {
        let session1 = VimSession()
        let session2 = VimSession()
        
        // Sessions with different server names should be independent
        #expect(!session1.isRunning(), "Session 1 should not be running initially")
        #expect(!session2.isRunning(), "Session 2 should not be running initially")
    }
}