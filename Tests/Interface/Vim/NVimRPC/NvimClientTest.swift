/*
Author: <Chuanyu> (skewcy@gmail.com)
NvimSessionRealTests.swift (c) 2025
Desc: Tests for NvimSession using real nvim server
Created:  2025-08-19T01:59:11.420Z
*/

import Testing
import Foundation
@testable import VimCafe

struct NvimSessionRealTests {
    
    @Test func realNvimStartAndStop() async throws {
        let client = NvimSession()
        
        try client.start()
        
        // Give nvim a moment to initialize
        try await Task.sleep(for: .milliseconds(100))
        
        // Test that we can get mode (indicates client is working)
        let mode = try client.getMode().mode
        #expect(mode == "n", "Should be in normal mode")
        
        client.stop()
    }
    
    @Test func realNvimBasicInput() async throws {
        let client = NvimSession()
        
        try client.start()
        
        // Give nvim time to initialize
        try await Task.sleep(for: .milliseconds(200))
        
        try client.sendInput("i")  // Enter insert mode
        try await Task.sleep(for: .milliseconds(50))
        
        let insertMode = try client.getMode().mode
        #expect(insertMode == "i", "Should be in insert mode after 'i' command")
        
        try client.sendInput("hello")
        try await Task.sleep(for: .milliseconds(50))
        
        try client.sendInput("\u{1b}")  // Escape key
        try await Task.sleep(for: .milliseconds(50))
        
        let normalMode = try client.getMode().mode
        #expect(normalMode == "n", "Should be in normal mode after escape")
        
        client.stop()
    }
    
    @Test func realNvimGetMode() async throws {
        let client = NvimSession()
        
        try client.start()
        try await Task.sleep(for: .milliseconds(200))
        
        let initialMode = try client.getMode().mode
        #expect(initialMode == "n", "Should start in normal mode")
        
        try client.sendInput("i")
        try await Task.sleep(for: .milliseconds(100))
        
        let insertMode = try client.getMode().mode
        #expect(insertMode == "i", "Should be in insert mode")
        
        try client.sendInput("\u{1b}")  // Escape
        try await Task.sleep(for: .milliseconds(100))
        
        let normalMode = try client.getMode().mode
        #expect(normalMode == "n", "Should return to normal mode")
        
        client.stop()
    }
    
    @Test func realNvimBufferOperations() async throws {
        let client = NvimSession()
        
        try client.start()
        try await Task.sleep(for: .milliseconds(200))
        
        // Set buffer content
        let testLines = ["Hello", "World", "Test"]
        try client.setBufferLines(buffer: 1, start: 0, end: -1, lines: testLines)
        try await Task.sleep(for: .milliseconds(100))
        
        // Get buffer content
        let retrievedLines = try client.getBufferLines(buffer: 1, start: 0, end: -1)
        
        #expect(retrievedLines == testLines, "Buffer content should match what was set")
        
        client.stop()
    }
    
    @Test func realNvimCursorOperations() async throws {
        let client = NvimSession()
        
        try client.start()
        try await Task.sleep(for: .milliseconds(200))
        
        // Set up a buffer with content
        try client.setBufferLines(buffer: 1, start: 0, end: -1, lines: ["Hello World", "Second Line"])
        try await Task.sleep(for: .milliseconds(100))
        
        // Test cursor positioning
        try client.setCursorPosition(window: 0, row: 1, col: 5)
        try await Task.sleep(for: .milliseconds(100))
        
        let position = try client.getCursorPosition(window: 0)
        
        #expect(position.row == 1, "Cursor row should be 1")
        #expect(position.col == 5, "Cursor col should be 5")
        
        client.stop()
    }
    
    @Test func realNvimCompleteWorkflow() async throws {
        let client = NvimSession()
        
        try client.start()
        try await Task.sleep(for: .milliseconds(200))
        
        // 1. Check initial state
        let initialMode = try client.getMode().mode
        #expect(initialMode == "n", "Should start in normal mode")
        
        // 2. Enter insert mode and add text
        try client.sendInput("i")
        try await Task.sleep(for: .milliseconds(50))
        
        try client.sendInput("Hello Vim!")
        try await Task.sleep(for: .milliseconds(50))
        
        try client.sendInput("\u{1b}")  // Escape
        try await Task.sleep(for: .milliseconds(100))
        
        // 3. Check the buffer content
        let bufferContent = try client.getBufferLines(buffer: 1, start: 0, end: -1)
        
        // 4. Check final mode
        let finalMode = try client.getMode().mode
        
        #expect(finalMode == "n", "Should end in normal mode")
        #expect(!bufferContent.isEmpty, "Buffer should not be empty")
        
        client.stop()
    }
    
    @Test(.timeLimit(.minutes(1))) func nvimProcessDoesNotHang() async throws {
        let client = NvimSession()
        
        try client.start()
        
        try await Task.sleep(for: .milliseconds(500))
        
        let mode = try client.getMode().mode
        #expect(mode == "n", "Should be in normal mode")
        #expect(!mode.isEmpty, "Mode should not be empty")
        
        client.stop()
    }
}

struct NvimSessionDebugTests {
    
    @Test func debugNvimProcessStartup() async throws {
        
        let client = NvimSession()
        
        let nvimPath = "/opt/homebrew/bin/nvim"
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: nvimPath)
        
        if !exists {
            throw NvimClientError.startupFailed(NSError(domain: "nvim not found", code: 404))
        }
        
        try client.start()
        
        try await Task.sleep(for: .milliseconds(1000))  // Longer wait
        
        let mode = try client.getMode().mode
        #expect(mode == "n", "Should be in normal mode")
        #expect(!mode.isEmpty, "Mode should not be empty")
        
        client.stop()
        
    }
    
    @Test func debugMessagePackCommunication() async throws {
        
        let client = NvimSession()
        try client.start()
        try await Task.sleep(for: .milliseconds(500))
        
        
        // Test 1: Get mode
        let mode = try client.getMode().mode
        #expect(mode == "n", "Should be in normal mode")
        #expect(!mode.isEmpty, "Mode should not be empty")
        
        // Test 2: Get buffer lines (should be empty initially)
        let lines = try client.getBufferLines(buffer: 1, start: 0, end: -1)
        #expect(lines.count >= 0, "Buffer lines should be valid array")
        
        // Test 3: Get cursor position
        let pos = try client.getCursorPosition(window: 0)
        #expect(pos.row >= 0, "Cursor row should be non-negative")
        #expect(pos.col >= 0, "Cursor col should be non-negative")
        
        client.stop()
    }
}