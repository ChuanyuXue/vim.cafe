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
    
    @Test func testEncodeDecodeString() throws {
        let testString = "hello world"
        let encoded = try NvimRPC.encode(testString)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        #expect(decoded[0] as? String == testString, "Decoded string should match original")
    }
    
    @Test func testEncodeDecodeInt() throws {
        let testInt = 42
        let encoded = try NvimRPC.encode(testInt)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        #expect(decoded[0] as? Int == testInt, "Decoded int should match original")
    }
    
    @Test func testEncodeDecodeUInt32() throws {
        let testUInt: UInt32 = 12345
        let encoded = try NvimRPC.encode(testUInt)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        #expect(decoded[0] as? Int == Int(testUInt), "Decoded UInt32 should match original")
    }
    
    @Test func testEncodeDecodeBool() throws {
        let testBoolTrue = true
        let encodedTrue = try NvimRPC.encode(testBoolTrue)
        let decodedTrue = try NvimRPC.decode(encodedTrue)
        
        #expect(decodedTrue.count == 1, "Should decode to single element")
        #expect(decodedTrue[0] as? Bool == true, "Decoded bool should be true")
        
        let testBoolFalse = false
        let encodedFalse = try NvimRPC.encode(testBoolFalse)
        let decodedFalse = try NvimRPC.decode(encodedFalse)
        
        #expect(decodedFalse.count == 1, "Should decode to single element")
        #expect(decodedFalse[0] as? Bool == false, "Decoded bool should be false")
    }
    
    @Test func testEncodeDecodeArray() throws {
        let testArray: [Any] = ["hello", 42, true, "world"]
        let encoded = try NvimRPC.encode(testArray)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        
        guard let decodedArray = decoded[0] as? [Any] else {
            Issue.record("Decoded value should be an array")
            return
        }
        
        #expect(decodedArray.count == 4, "Should have 4 elements")
        #expect(decodedArray[0] as? String == "hello", "First element should be 'hello'")
        #expect(decodedArray[1] as? Int == 42, "Second element should be 42")
        #expect(decodedArray[2] as? Bool == true, "Third element should be true")
        #expect(decodedArray[3] as? String == "world", "Fourth element should be 'world'")
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
    
    @Test func testEncodeDecodeNegativeInt() throws {
        let testInt = -42
        let encoded = try NvimRPC.encode(testInt)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        #expect(decoded[0] as? Int == testInt, "Decoded negative int should match original")
    }
    
    @Test func testEncodeDecodeLargeString() throws {
        let testString = String(repeating: "a", count: 1000)
        let encoded = try NvimRPC.encode(testString)
        let decoded = try NvimRPC.decode(encoded)
        
        #expect(decoded.count == 1, "Should decode to single element")
        #expect(decoded[0] as? String == testString, "Decoded large string should match original")
    }
}

// MARK: - Part 2: NvimSession Basic Functionality Tests
struct NvimSessionBasicTests {
    
    @Test func testNvimSessionStartStop() throws {
        let session = NvimSession()
        
        #expect(!session.isRunning(), "Session should not be running initially")
        
        try session.start()
        #expect(session.isRunning(), "Session should be running after start")
        
        session.stop()
        #expect(!session.isRunning(), "Session should not be running after stop")
    }
    
    @Test func testNvimSessionGetMode() async throws {
        let session = NvimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should start in normal mode")
        #expect(!mode.blocking, "Should not be blocking initially")
        
        session.stop()
    }
    
    @Test func testNvimSessionSendInput() async throws {
        let session = NvimSession()
        
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
    
    @Test func testNvimSessionBufferOperations() async throws {
        let session = NvimSession()
        
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
    
    @Test func testNvimSessionCursorOperations() async throws {
        let session = NvimSession()
        
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
    
    @Test func testNvimSessionEmptyBuffer() async throws {
        let session = NvimSession()
        
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
    
    @Test func testNvimSessionTimeout() async throws {
        let session = NvimSession()
        
        try session.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let mode = try session.getMode()
        #expect(mode.mode == "n", "Should respond within timeout")
        
        session.stop()
    }
}

// MARK: - Part 3: Multiple NvimSession Tests
struct NvimSessionMultipleInstanceTests {
    
    @Test func testMultipleSessionsIndependence() async throws {
        let session1 = NvimSession()
        let session2 = NvimSession()
        
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
        let session1 = NvimSession()
        let session2 = NvimSession()
        
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
        let session1 = NvimSession()
        let session2 = NvimSession()
        
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
        let session1 = NvimSession()
        
        try session1.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let testContent = ["Existing session content"]
        try session1.setBufferLines(buffer: 1, start: 0, end: -1, lines: testContent)
        try await Task.sleep(for: .milliseconds(100))
        
        let session2 = NvimSession()
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
        let session1 = NvimSession()
        let session2 = NvimSession()
        let session3 = NvimSession()
        
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
        let sessions = (0..<5).map { _ in NvimSession() }
        
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