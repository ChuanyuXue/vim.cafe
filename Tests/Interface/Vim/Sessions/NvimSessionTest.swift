/*
Author: <Chuanyu> (skewcy@gmail.com)
NvimClientTest.swift (c) 2025
Desc: Comprehensive tests for NvimRPC and NvimSession functionality
Created:  2025-08-19T01:59:11.420Z
*/

import Testing
import Foundation
@testable import VimCafe

// MARK: - Part 1: NvimRPC Encode/Decode Tests
struct NvimRPCTests {
    
    @Test func testCreateRequest() {
        let request = NvimRPC.createRequest(id: 1, method: "test_method", params: ["param1", 42])
        
        #expect(request.count == 4, "Request should have 4 elements")
        #expect(request[0] as? Int == 0, "First element should be 0 (request type)")
        #expect(request[1] as? UInt32 == 1, "Second element should be message ID")
        #expect(request[2] as? String == "test_method", "Third element should be method name")
        
        if let params = request[3] as? [Any] {
            #expect(params.count == 2, "Should have 2 parameters")
            #expect(params[0] as? String == "param1", "First param should be 'param1'")
            #expect(params[1] as? Int == 42, "Second param should be 42")
        } else {
            Issue.record("Parameters should be an array")
        }
    }
    
    @Test func testEncodeDecodeRequest() throws {
        let request = NvimRPC.createRequest(id: 1, method: "nvim_input", params: ["hello world"])
        let encoded = try NvimRPC.encode(request)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC request should have 4 elements")
        #expect(decoded[0] as? Int == 0, "First element should be 0 (request type)")
        #expect(decoded[1] as? Int == 1, "Second element should be message ID")
        #expect(decoded[2] as? String == "nvim_input", "Third element should be method name")
        #expect((decoded[3] as? [Any])?.count == 1, "Fourth element should have 1 parameter")
        #expect((decoded[3] as? [Any])?[0] as? String == "hello world", "Parameter should be 'hello world'")
    }
    
    @Test func testEncodeDecodeRequestWithInt() throws {
        let request = NvimRPC.createRequest(id: 42, method: "nvim_buf_get_lines", params: [1, 0, -1, false])
        let encoded = try NvimRPC.encode(request)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC request should have 4 elements")
        #expect(decoded[0] as? Int == 0, "First element should be 0 (request type)")
        #expect(decoded[1] as? Int == 42, "Second element should be message ID")
        #expect(decoded[2] as? String == "nvim_buf_get_lines", "Third element should be method name")
        #expect((decoded[3] as? [Any])?.count == 4, "Fourth element should have 4 parameters")
    }
    
    @Test func testEncodeDecodeResponse() throws {
        let response: [Any] = [1, UInt32(12345), NSNull(), ["result", "data"]]
        let encoded = try NvimRPC.encode(response)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC response should have 4 elements")
        #expect(decoded[0] as? Int == 1, "First element should be 1 (response type)")
        #expect(decoded[1] as? Int == 12345, "Second element should be message ID")
        #expect(decoded[2] is NSNull, "Third element should be null (no error)")
        #expect((decoded[3] as? [Any])?.count == 2, "Fourth element should be result array")
    }
    
    @Test func testEncodeDecodeRequestWithBool() throws {
        let request = NvimRPC.createRequest(id: 1, method: "nvim_buf_set_lines", params: [1, 0, -1, false, ["line1", "line2"]])
        let encoded = try NvimRPC.encode(request)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC request should have 4 elements")
        #expect(decoded[0] as? Int == 0, "First element should be 0 (request type)")
        #expect(decoded[1] as? Int == 1, "Second element should be message ID")
        #expect(decoded[2] as? String == "nvim_buf_set_lines", "Third element should be method name")
        
        let params = decoded[3] as? [Any]
        #expect(params?.count == 5, "Should have 5 parameters")
        #expect(params?[3] as? Bool == false, "Fourth parameter should be false")
        #expect((params?[4] as? [Any])?.count == 2, "Fifth parameter should be array with 2 lines")
    }
    
    @Test func testEncodeDecodeNotification() throws {
        let notification: [Any] = [2, "nvim_buf_lines_event", [1, 0, 5, ["new line"], false]]
        let encoded = try NvimRPC.encode(notification)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 3, "RPC notification should have 3 elements")
        #expect(decoded[0] as? Int == 2, "First element should be 2 (notification type)")
        #expect(decoded[1] as? String == "nvim_buf_lines_event", "Second element should be event name")
        
        let params = decoded[2] as? [Any]
        #expect(params?.count == 5, "Third element should have 5 parameters")
        #expect(params?[0] as? Int == 1, "First param should be buffer ID")
        #expect((params?[3] as? [Any])?.count == 1, "Fourth param should be lines array")
    }
    
    @Test func testEncodeDecodeComplexRequest() throws {
        let request = NvimRPC.createRequest(id: 123, method: "nvim_get_mode", params: [])
        let encoded = try NvimRPC.encode(request)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "Request should have 4 elements")
        #expect(decoded[0] as? Int == 0, "First element should be 0")
        #expect(decoded[1] as? Int == 123, "Second element should be message ID")
        #expect(decoded[2] as? String == "nvim_get_mode", "Third element should be method name")
        #expect((decoded[3] as? [Any])?.count == 0, "Fourth element should be empty params array")
    }
    
    @Test func testEncodeDecodeErrorResponse() throws {
        let errorResponse: [Any] = [1, UInt32(42), "Invalid buffer", NSNull()]
        let encoded = try NvimRPC.encode(errorResponse)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC error response should have 4 elements")
        #expect(decoded[0] as? Int == 1, "First element should be 1 (response type)")
        #expect(decoded[1] as? Int == 42, "Second element should be message ID")
        #expect(decoded[2] as? String == "Invalid buffer", "Third element should be error message")
        #expect(decoded[3] is NSNull, "Fourth element should be null (no result)")
    }
    
    @Test func testEncodeDecodeRequestWithLargeData() throws {
        let largeString = String(repeating: "a", count: 1000)
        let request = NvimRPC.createRequest(id: 999, method: "nvim_command", params: [largeString])
        let encoded = try NvimRPC.encode(request)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 4, "RPC request should have 4 elements")
        #expect(decoded[2] as? String == "nvim_command", "Third element should be method name")
        #expect((decoded[3] as? [Any])?[0] as? String == largeString, "Parameter should match large string")
    }
}

// MARK: - Part 2: NvimSession Basic Functionality Tests
struct NvimSessionBasicTests {
    
    @Test func testNvimSessionStartStop() throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        
        #expect(session.isRunning(), "Session should be running after creation")
        #expect(session.isRunning(), "Session should be running after start")
        
        session.stop()
        #expect(!session.isRunning(), "Session should not be running after stop")
    }
    
    @Test func testNvimSessionGetMode() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should start in normal mode")
        #expect(!mode.blocking, "Should not be blocking initially")
        
        session.stop()
    }
    
    @Test func testNvimSessionSendInput() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
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
    
    @Test func testNvimSessionBufferOperations() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
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
    
    @Test func testNvimSessionCursorOperations() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
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
    
    @Test func testNvimSessionEmptyBuffer() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
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
    
    @Test func testNvimSessionTimeout() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should respond within timeout")
        
        session.stop()
    }
}

// MARK: - Part 3: Multiple NvimSession Tests
struct NvimSessionMultipleInstanceTests {
    
    @Test func testMultipleSessionsIndependence() async throws {
        let session1 = try SessionManager.shared.createAndStartSession(type: .nvim)
        let session2 = try SessionManager.shared.createAndStartSession(type: .nvim)
        
        
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
        let session1 = try SessionManager.shared.createAndStartSession(type: .nvim)
        let session2 = try SessionManager.shared.createAndStartSession(type: .nvim)
        
        
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
        let session1 = try SessionManager.shared.createAndStartSession(type: .nvim)
        let session2 = try SessionManager.shared.createAndStartSession(type: .nvim)
        
        
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
        let session1 = try SessionManager.shared.createAndStartSession(type: .nvim)
        
        try session1.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let testContent = ["Existing session content"]
        try session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testContent)
        try await Task.sleep(for: .milliseconds(100))
        
        let session2 = try SessionManager.shared.createAndStartSession(type: .nvim)
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

    @Test func testSessionMode() async throws {   
        // Test insert, normal, replace, visual, command
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)

        try session.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))

        let mode = try session.getMode()
        #expect(mode.mode == "i", "Should be in insert mode after 'i' command")

        try session.sendInput("<Esc>")
        try await Task.sleep(for: .milliseconds(100))

        let normalMode = try session.getMode()
        #expect(normalMode.mode == "n", "Should return to normal mode after escape")

        try session.sendInput("r")
        try await Task.sleep(for: .milliseconds(100))

        let replaceMode = try session.getMode()
        #expect(replaceMode.mode == "R", "Should be in replace mode after 'R' command")

        try session.sendInput("<Esc>")
        try session.sendInput("<C-V>")
        try await Task.sleep(for: .milliseconds(100))

        let visualMode = try session.getMode()
        if !visualMode.blocking {
            #expect(visualMode.mode == "v", "Should be in visual mode after '<C-V>' command")
        }

        try session.sendInput("<Esc>")
        try session.sendInput(":")
        try await Task.sleep(for: .milliseconds(100))

        let commandMode = try session.getMode()
        #expect(commandMode.mode == "c", "Should be in command mode after ':' command")
    }

    
    @Test func testStoppingOneSessionDoesNotAffectOthers() async throws {
        let session1 = try SessionManager.shared.createAndStartSession(type: .nvim)
        let session2 = try SessionManager.shared.createAndStartSession(type: .nvim)
        let session3 = try SessionManager.shared.createAndStartSession(type: .nvim)
        
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
        let sessions = try (0..<5).map { _ in 
            try SessionManager.shared.createAndStartSession(type: .nvim)
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

struct NvimSessionPerformanceTests {
    @Test func createSessionTime() async throws {
        let startTime = Date()
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Session creation time: \(duration) seconds")
        session.stop()
    }

    @Test func stopSessionTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        session.stop()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Session stop time: \(duration) seconds")
    }

    @Test func sendInputTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        try session.sendInput("i")
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Send input time: \(duration) seconds")
        session.stop()
    }

    @Test func getModeTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        let mode = try session.getMode()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get mode time: \(duration) seconds")
        session.stop()
    }

    @Test func getBufferLinesTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        let lines = try session.getBufferLines(buffer: 1, start: 0, end: -1)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get buffer lines time: \(duration) seconds")
        session.stop()
    }

    @Test func getCursorPositionTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        let position = try session.getCursorPosition(window: 0)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Get cursor position time: \(duration) seconds")
        session.stop()
    }

    @Test func setBufferLinesTime() async throws {
        let session = try SessionManager.shared.createAndStartSession(type: .nvim)
        let startTime = Date()
        let lines = ["Line 1", "Line 2", "Line 3"]
        try session.setBufferLines(buffer: 1, start: 0, end: -1, lines: lines)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("⏱️ Set buffer lines time: \(duration) seconds")
        session.stop()
    }
}