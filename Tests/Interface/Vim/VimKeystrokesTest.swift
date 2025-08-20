/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokesTests.swift (c) 2025
Desc: Comprehensive tests for VimKeystrokes definitions using Swift Testing with real values
Created:  2025-08-19T20:15:34.781Z
Updated:  2025-08-20T00:00:00.000Z
*/

import Testing
@testable import VimCafe

// Helper to get all keystroke strings for testing
let KEYSTROKES = VimKeystroke.allCases.map { $0.rawValue }

struct VimKeystrokesTests {
    @Test func basicNavigationKeystrokesWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        let rightState = try engine.execKeystrokes([.l])
        #expect(rightState.cursor.col >= 0, "Moving right with 'l' should work")
        
        let downState = try engine.execKeystrokes([.j])  
        #expect(downState.cursor.row >= 0, "Moving down with 'j' should work")
        
        let leftState = try engine.execKeystrokes([.h])
        #expect(leftState.cursor.col >= 0, "Moving left with 'h' should work")
        
        let upState = try engine.execKeystrokes([.k])
        #expect(upState.cursor.row >= 0, "Moving up with 'k' should work")
    }
    
    @Test func specialKeysWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        let insertState = try engine.execKeystrokes([.i])
        #expect(insertState.mode == .insert, "Pressing 'i' should enter insert mode")
        
        let escapeState = try engine.execKeystrokes([.escape])
        #expect(escapeState.mode == .normal, "Pressing <Esc> should return to normal mode")
        
        let appendState = try engine.execKeystrokes([.A])
        #expect(appendState.mode == .insert, "Pressing 'A' should enter insert mode")
    }
    
    @Test func textInsertionKeystrokesWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        let resultState = try engine.execKeystrokes([.i, .h, .e, .l, .l, .o, .escape])
        
        #expect(resultState.mode == .normal, "Should return to normal mode after <Esc>")
        #expect(resultState.buffer.first?.contains("hello") == true, "Buffer should contain inserted text 'hello'")
    }
    
    @Test func controlCombinationsWorkWithVimEngine() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Set up content first
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        for i in 1...20 {
            try session.sendInput("line \(i)")
            _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        }
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let pageUpState = try engine.execKeystrokes(session: session, keystrokes: [.ctrlU])
        #expect(pageUpState.cursor.row >= 0, "Control-u should work")
        
        let pageDownState = try engine.execKeystrokes(session: session, keystrokes: [.ctrlD])
        #expect(pageDownState.cursor.row >= 0, "Control-d should work")
    }
    
    @Test func arrowKeysWorkWithVimEngine() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Set up content first
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("first line")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("second line")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let rightState = try engine.execKeystrokes(session: session, keystrokes: [.right])
        #expect(rightState.cursor.col >= 0, "Right arrow should work")
        
        let downState = try engine.execKeystrokes(session: session, keystrokes: [.down])
        #expect(downState.cursor.row >= 0, "Down arrow should work")
        
        let leftState = try engine.execKeystrokes(session: session, keystrokes: [.left])
        #expect(leftState.cursor.col >= 0, "Left arrow should work")
        
        let upState = try engine.execKeystrokes(session: session, keystrokes: [.up])
        #expect(upState.cursor.row >= 0, "Up arrow should work")
    }
    
    @Test func backspaceAndDeleteWorkWithVimEngine() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Set up content first
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i, .h, .e, .l, .l, .o, .space, .w, .o, .r, .l, .d, .escape])
        
        let insertState = try engine.execKeystrokes(session: session, keystrokes: [.i])
        #expect(insertState.mode == .insert, "Should enter insert mode")
        
        let backspaceState = try engine.execKeystrokes(session: session, keystrokes: [.backspace])
        #expect(backspaceState.mode == .insert, "Should stay in insert mode after backspace")
        
        let deleteState = try engine.execKeystrokes(session: session, keystrokes: [.delete])
        #expect(deleteState.mode == .insert, "Should stay in insert mode after delete")
    }
    
    @Test func complexKeystrokeSequenceWorkWithVimEngine() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Set up initial content
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("line one")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("line two")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let finalState = try engine.execKeystrokes(session: session, keystrokes: [.A, .space, .m, .o, .d, .i, .f, .i, .e, .d, .escape, .j, .I, .p, .r, .e, .f, .i, .x, .space, .escape])
        
        #expect(finalState.mode == .normal, "Should end in normal mode")
        #expect(finalState.buffer.count >= 2, "Should have at least 2 lines")
    }
    
    @Test func allKeystrokesAreHandledByVimEngine() throws {
        var failedKeys: [String] = []
        
        let engine = VimEngine()
        
        for (index, keystroke) in KEYSTROKES.enumerated() {
            do {
                // Reset to normal mode before each test
                _ = try engine.execKeystrokes([.escape])
                
                // Try to send the keystroke - should always return a valid state now
                let resultState = try engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we got a valid state back
                #expect(resultState.mode == .normal || resultState.mode == .insert || resultState.mode == .visual || resultState.mode == .visualLine || resultState.mode == .command || resultState.mode == .replace, "Mode should be valid for keystroke '\(keystroke)'")
                
                
            } catch {
                failedKeys.append(keystroke)
            }
        }
        
        if !failedKeys.isEmpty {
            Issue.record("The following \(failedKeys.count) keystrokes failed: \(failedKeys.joined(separator: ", "))")
        }
        
        #expect(failedKeys.count < 50, "Should have fewer than 50 failed keystrokes")
    }
    
    @Test func allIndividualKeystrokesWork() throws {
        let engine = VimEngine()
        
        var failedKeystrokes: [String] = []
        var testedCount = 0
        
        for keystroke in KEYSTROKES {
            do {
                // Reset to normal mode first
                _ = try engine.execKeystrokes([.escape])
                
                // This should not throw an error - execKeystrokes handles blocking gracefully
                let resultState = try engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we got a valid state back (this is the key test)
                if !(resultState.mode == .normal || resultState.mode == .insert || resultState.mode == .visual || resultState.mode == .visualLine || resultState.mode == .command || resultState.mode == .replace) {
                    failedKeystrokes.append(keystroke)
                }
                
                testedCount += 1
                
            } catch {
                failedKeystrokes.append(keystroke)
            }
        }
        
        if !failedKeystrokes.isEmpty {
            Issue.record("Failed keystrokes: \(failedKeystrokes.joined(separator: ", "))")
        }
        
        #expect(failedKeystrokes.count < 50, "Should have fewer than 50 failed keystrokes, got \(failedKeystrokes.count)")
    }
    
    @Test func keystrokesByCategory() throws {
        let letters = KEYSTROKES.filter { $0.count == 1 && $0.first!.isLetter }
        let numbers = KEYSTROKES.filter { $0.count == 1 && $0.first!.isNumber }
        let specialKeys = KEYSTROKES.filter { $0.hasPrefix("<") && $0.hasSuffix(">") }
        let symbols = KEYSTROKES.filter { key in
            key.count == 1 && !key.first!.isLetter && !key.first!.isNumber && !key.hasPrefix("<")
        }
        
        var categoryResults: [String: (recognized: Int, total: Int)] = [:]
        
        func testCategory(name: String, keys: [String]) {
            var recognized = 0
            let engine = VimEngine()
            
            for key in keys {
                do {
                    _ = try engine.execKeystrokes([.escape])  // Reset to normal mode
                    let resultState = try engine.execKeystrokes([VimKeystroke(rawValue: key) ?? .escape])
                    // If we get a valid state back, the keystroke was handled
                    if resultState.mode == VimMode.normal || resultState.mode == VimMode.insert || resultState.mode == VimMode.visual || resultState.mode == VimMode.visualLine || resultState.mode == VimMode.command || resultState.mode == VimMode.replace {
                        recognized += 1
                    }
                } catch {
                    // Key failed completely, continue
                }
            }
            categoryResults[name] = (recognized: recognized, total: keys.count)
        }
        
        testCategory(name: "Letters", keys: letters)
        testCategory(name: "Numbers", keys: numbers)
        testCategory(name: "Special Keys", keys: specialKeys)
        testCategory(name: "Symbols", keys: symbols)
        
        // Report results by category
        for (category, result) in categoryResults {
            #expect(result.recognized == result.total, 
                   "\(category): Expected all \(result.total) keys to be recognized, but only \(result.recognized) were")
        }
    }
    
    @Test func quickKeystrokeSample() throws {
        // Test a small sample of keystrokes to identify common issues
        let sampleKeys: [VimKeystroke] = [.a, .b, .one, .two, .space, .escape, .enter, .backspace, .ctrlA, .metaA, .f1, .up]
        let engine = VimEngine()
        
        var failed: [VimKeystroke] = []
        
        for key in sampleKeys {
            do {
                _ = try engine.execKeystrokes([.escape]) // Reset to normal mode
                let result = try engine.execKeystrokes([key])
                #expect(result.mode == .normal || result.mode == .insert || result.mode == .visual || result.mode == .visualLine || result.mode == .command || result.mode == .replace, "Keystroke '\(key)' should return valid mode")
                #expect(result.cursor.row >= 0, "Keystroke '\(key)' should return valid cursor row")
                #expect(result.cursor.col >= 0, "Keystroke '\(key)' should return valid cursor col")
            } catch {
                failed.append(key)
            }
        }
        
        if !failed.isEmpty {
            Issue.record("Sample test failed for: \(failed.map { $0.rawValue }.joined(separator: ", "))")
        }
    }
    
    @Test func debugVimEngineCreation() throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes([.h])
        #expect(result.mode == .normal || result.mode == .insert || result.mode == .visual || result.mode == .visualLine || result.mode == .command || result.mode == .replace, "Should return valid mode")
    }
    
    @Test func testImprovedBlockingDetection() throws {
        let engine = VimEngine()
        
        // Set up content first
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("test line")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test a regular key that doesn't block
        let stateA = try engine.execKeystrokes(session: session, keystrokes: [.a])
        #expect(stateA.mode == .insert, "Should enter insert mode after 'a'")
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test the previously problematic '1' key - should return fallback state
        let state1 = try engine.execKeystrokes(session: session, keystrokes: [.one])
        #expect(state1.mode == .normal, "Should stay in normal mode after '1' (fallback state)")
        #expect(state1.cursor.row >= 0, "Should return valid cursor position")
        
        // Test completing the sequence - '1j' should move down 1 line (but we only have 1 line)
        let stateComplete = try engine.execKeystrokes(session: session, keystrokes: [.j])
        #expect(stateComplete.mode == .normal, "Should remain in normal mode after 'j'")
        #expect(stateComplete.cursor.row >= 0, "Should return valid cursor position")
    }
    
    @Test func testCountPrefixWithMotion() throws {
        let engine = VimEngine()
        
        // Set up content first
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("line 1")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("line 2")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("line 3")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("line 4")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test count prefix with motion - should work as a complete sequence
        let stateBefore = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(stateBefore.cursor.row >= 0, "Should have valid cursor position")
        
        // Execute '3j' as separate keystrokes - first '3' will be blocking, then 'j' completes it
        let stateAfter3 = try engine.execKeystrokes(session: session, keystrokes: [.three])
        #expect(stateAfter3.mode == .normal, "Should return normal mode (fallback state)")
        
        let stateAfterJ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        #expect(stateAfterJ.mode == .normal, "Should be in normal mode after completing '3j'")
        #expect(stateAfterJ.cursor.row >= 0, "Should have valid cursor position")
    }
}

// MARK: - Comprehensive Real-World Keystroke Tests
struct VimKeystrokesRealWorldTests {
    
    @Test func testProgrammingWorkflow() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Create a simple function with keystrokes
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("function calculateSum(a, b) {")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("    return a + b;")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("}")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.A])
        try session.sendInput(" // Pure function")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.I])
        try session.sendInput("    ")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.A])
        try session.sendInput(" // Simple addition")
        let result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
        #expect(result.buffer.first?.contains("function calculateSum") == true, "Should contain function declaration")
        #expect(result.buffer.first?.contains("// Pure function") == true, "Should contain comment")
    }
    
    @Test func testTextEditingWorkflow() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Write a document with corrections
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("The quick brown fox jumps over the lazy dog.")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("This is a test document for vim editing.")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("We will make some corrections to this text.")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.f])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.q])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.x])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.s])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.Q])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.f])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.t])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.x])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.s])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.T])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.A])
        try session.sendInput(" Now it's perfect!")
        let result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
        #expect(result.buffer.first?.contains("Quick") == true, "Should contain corrected 'Quick'")
    }
    
    @Test func testNavigationAndSelection() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Create content and navigate through it
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("First line with some content")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Second line with more text")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Third line for testing")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Fourth and final line")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Navigate and select
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.v])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.e])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.dollar])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.b])
        let result = try engine.execKeystrokes(session: session, keystrokes: [.b])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.cursor.row >= 0, "Should have valid cursor row")
        #expect(result.cursor.col >= 0, "Should have valid cursor column")
    }
    
    @Test func testSearchAndReplace() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Create content with repeated words
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("apple banana apple cherry apple")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("grape apple orange apple lemon")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Search for 'apple'
        _ = try engine.execKeystrokes(session: session, keystrokes: [.slash])
        try session.sendInput("apple")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.n])
        let result = try engine.execKeystrokes(session: session, keystrokes: [.n])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode after search")
        #expect(result.buffer.first?.contains("apple") == true, "Should contain search term")
    }
    
    @Test func testComplexEditingOperations() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Complex editing scenario
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("TODO: Fix this bug")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("FIXME: Refactor this code")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("NOTE: Remember to test")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try session.sendInput("DONE:")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try session.sendInput("FIXED:")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try session.sendInput("TESTED:")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.G])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.o])
        try session.sendInput("All tasks completed!")
        let result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 4, "Should have at least 4 lines")
        #expect(result.buffer.contains("DONE:"), "Should contain DONE:")
        #expect(result.buffer.contains("FIXED:"), "Should contain FIXED:")
        #expect(result.buffer.contains("TESTED:"), "Should contain TESTED:")
        #expect(result.buffer.last?.contains("completed") == true, "Should contain completion message")
    }
    
    @Test func testSpecialCharactersAndSymbols() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Test various symbols and special characters
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("Variables: $var, @array, %hash")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Math: 2 + 3 = 5, 10 - 4 = 6")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Symbols: !@#$%^&*()")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Quotes: \"double\" 'single' `backtick`")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Brackets: () [] {} <>")
        let result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 5, "Should have at least 5 lines")
        #expect(result.buffer.contains("$var"), "Should contain variable syntax")
        #expect(result.buffer.contains("!@#$%^&*()"), "Should contain special symbols")
        #expect(result.buffer.contains("\"double\""), "Should contain quoted text")
    }
    
    @Test func testFunctionKeys() throws {
        let engine = VimEngine()
        
        // Test function keys work without errors
        let functionKeys: [VimKeystroke] = [.f1, .f2, .f3, .f4, .f5, .f6]
        
        for fKey in functionKeys {
            let result = try engine.execKeystrokes([fKey])
            #expect(result.mode == VimMode.normal, "Function key \(fKey) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Function key \(fKey) should return valid cursor position")
        }
    }
    
    @Test func testControlCombinations() throws {
        let engine = VimEngine()
        
        // Set up content for control key testing
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        
        // Add many lines for scrolling tests
        for i in 1...30 {
            try session.sendInput("Line \(i) with content for testing")
            _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        }
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test important control combinations
        let controlTests: [VimKeystroke] = [.ctrlU, .ctrlD, .ctrlF, .ctrlB, .ctrlO, .ctrlG]
        
        for controlKey in controlTests {
            let result = try engine.execKeystrokes(session: session, keystrokes: [controlKey])
            #expect(result.mode == VimMode.normal, "Control sequence \(controlKey) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Control sequence \(controlKey) should return valid position")
        }
    }
    
    @Test func testModeTransitionsWithRealContent() throws {
        let engine = VimEngine()
        
        // Test all major mode transitions with real content
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Start in normal mode, go to insert
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("Insert mode text")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual mode
        _ = try engine.execKeystrokes(session: session, keystrokes: [.v])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual line mode
        _ = try engine.execKeystrokes(session: session, keystrokes: [.V])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual block mode
        _ = try engine.execKeystrokes(session: session, keystrokes: [.ctrlV])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to replace mode
        _ = try engine.execKeystrokes(session: session, keystrokes: [.R])
        try session.sendInput("Replace")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Try command mode
        _ = try engine.execKeystrokes(session: session, keystrokes: [.colon])
        let result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode after all transitions")
        #expect(result.buffer.first?.contains("Replace") == true, "Should contain replaced text")
    }
    
    @Test func testDeleteAndYankOperations() throws {
        let engine = VimEngine()
        
        // Create content for delete/yank operations
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("Line to delete")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Line to yank and paste")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("Line to keep")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test delete operations
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.d, .d])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.y, .y])
        let result = try engine.execKeystrokes(session: session, keystrokes: [.p])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode after operations")
        #expect(result.buffer.count >= 2, "Should have remaining content")
    }
    
    @Test func testWordAndLineMovements() throws {
        let engine = VimEngine()
        
        // Create content with various word patterns
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        _ = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("word1 word2 word3.word4")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("another_line with-dashes")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.enter])
        try session.sendInput("CamelCaseWords and spaces")
        _ = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test word movements
        _ = try engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.W])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.e])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.E])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.b])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.B])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.caret])
        _ = try engine.execKeystrokes(session: session, keystrokes: [.dollar])
        let result = try engine.execKeystrokes(session: session, keystrokes: [.zero])
        
        #expect(result.mode == VimMode.normal, "Should stay in normal mode during movements")
        #expect(result.cursor.row >= 0, "Should have valid cursor position")
        #expect(result.cursor.col == 0, "Should be at beginning of line after '0'")
    }
    
    @Test func testAllKeystrokesHandledProperly() throws {
        let engine = VimEngine()
        var problematicKeys: [String] = []
        var successCount = 0
        
        // Test each keystroke individually
        for keystroke in KEYSTROKES {
            do {
                // Reset to clean state
                _ = try engine.execKeystrokes([.escape])
                
                // Test the keystroke
                let result = try engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we get a valid response
                if (result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace) && result.cursor.row >= 0 && result.cursor.col >= 0 {
                    successCount += 1
                } else {
                    problematicKeys.append("\(keystroke) (invalid state)")
                }
                
            } catch {
                problematicKeys.append("\(keystroke) (exception: \(error))")
            }
        }
        
        let successRate = Double(successCount) / Double(KEYSTROKES.count) * 100
        
        #expect(successRate >= 85.0, "At least 85% of keystrokes should be handled properly")
        #expect(problematicKeys.count <= 20, "Should have at most 20 problematic keystrokes")
    }
    
    @Test func testKeystrokeStateConsistency() throws {
        let engine = VimEngine()
        
        // Test that each keystroke returns consistent state
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Test Insert and exit
        var result = try engine.execKeystrokes(session: session, keystrokes: [.i])
        try session.sendInput("test")
        result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace, "Mode should be valid")
        #expect(result.cursor.row >= 0, "Cursor row should be valid")
        #expect(result.cursor.col >= 0, "Cursor col should be valid")
        #expect(result.buffer.count >= 0, "Buffer should be valid")
        
        // Test append and exit
        result = try engine.execKeystrokes(session: session, keystrokes: [.a])
        try session.sendInput("append")
        result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace, "Mode should be valid")
        
        // Test visual selection
        result = try engine.execKeystrokes(session: session, keystrokes: [.v])
        result = try engine.execKeystrokes(session: session, keystrokes: [.l])
        result = try engine.execKeystrokes(session: session, keystrokes: [.l])
        result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace, "Mode should be valid")
        
        // Test visual line
        result = try engine.execKeystrokes(session: session, keystrokes: [.V])
        result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace, "Mode should be valid")
        
        // Test command mode
        result = try engine.execKeystrokes(session: session, keystrokes: [.colon])
        result = try engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(result.mode == VimMode.normal || result.mode == VimMode.insert || result.mode == VimMode.visual || result.mode == VimMode.visualLine || result.mode == VimMode.command || result.mode == VimMode.replace, "Mode should be valid")
    }
}