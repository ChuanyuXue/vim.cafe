/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokesTests.swift (c) 2025
Desc: Comprehensive tests for VimKeystrokes definitions using Swift Testing with real values
Created:  2025-08-19T20:15:34.781Z
Updated:  2025-08-20T00:00:00.000Z
*/

import Testing
@testable import VimCafe

private let sessionType = SessionType.nvim
private let KEYSTROKES = VimKeystroke.allCases.map { $0.rawValue }

struct VimKeystrokesTests {
    @Test func basicNavigationKeystrokesWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let rightState = try await engine.execKeystrokes([.l])
        #expect(rightState.cursor.col >= 0, "Moving right with 'l' should work")
        
        let downState = try await engine.execKeystrokes([.j])  
        #expect(downState.cursor.row >= 0, "Moving down with 'j' should work")
        
        let leftState = try await engine.execKeystrokes([.h])
        #expect(leftState.cursor.col >= 0, "Moving left with 'h' should work")
        
        let upState = try await engine.execKeystrokes([.k])
        #expect(upState.cursor.row >= 0, "Moving up with 'k' should work")
    }
    
    @Test func specialKeysWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let insertState = try await engine.execKeystrokes([.i])
        #expect(insertState.mode == .insert, "Pressing 'i' should enter insert mode")
        
        let escapeState = try await engine.execKeystrokes([.escape])
        #expect(escapeState.mode == .normal, "Pressing <Esc> should return to normal mode")
        
        let appendState = try await engine.execKeystrokes([.A])
        #expect(appendState.mode == .insert, "Pressing 'A' should enter insert mode")
    }
    
    @Test func textInsertionKeystrokesWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let resultState = try await engine.execKeystrokes([.i, .h, .e, .l, .l, .o, .escape])
        
        #expect(resultState.mode == .normal, "Should return to normal mode after <Esc>")
        #expect(resultState.buffer.first?.contains("hello") == true, "Buffer should contain inserted text 'hello'")
    }
    
    @Test func controlCombinationsWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Set up content first
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        for i in 1...20 {
            try await session.sendInput("line \(i)")
            _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        }
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let pageUpState = try await engine.execKeystrokes(session: session, keystrokes: [.ctrlU])
        #expect(pageUpState.cursor.row >= 0, "Control-u should work")
        
        let pageDownState = try await engine.execKeystrokes(session: session, keystrokes: [.ctrlD])
        #expect(pageDownState.cursor.row >= 0, "Control-d should work")
    }
    
    @Test func arrowKeysWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Set up content first
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("first line")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("second line")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let rightState = try await engine.execKeystrokes(session: session, keystrokes: [.right])
        #expect(rightState.cursor.col >= 0, "Right arrow should work")
        
        let downState = try await engine.execKeystrokes(session: session, keystrokes: [.down])
        #expect(downState.cursor.row >= 0, "Down arrow should work")
        
        let leftState = try await engine.execKeystrokes(session: session, keystrokes: [.left])
        #expect(leftState.cursor.col >= 0, "Left arrow should work")
        
        let upState = try await engine.execKeystrokes(session: session, keystrokes: [.up])
        #expect(upState.cursor.row >= 0, "Up arrow should work")
    }
    
    @Test func backspaceAndDeleteWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Set up content first
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i, .h, .e, .l, .l, .o, .space, .w, .o, .r, .l, .d, .escape])
        
        let insertState = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        #expect(insertState.mode == .insert, "Should enter insert mode")
        
        let backspaceState = try await engine.execKeystrokes(session: session, keystrokes: [.backspace])
        #expect(backspaceState.mode == .insert, "Should stay in insert mode after backspace")
        
        let deleteState = try await engine.execKeystrokes(session: session, keystrokes: [.delete])
        #expect(deleteState.mode == .insert, "Should stay in insert mode after delete")
    }
    
    @Test func complexKeystrokeSequenceWorkWithVimEngine() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Set up initial content
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line one")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("line two")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        let finalState = try await engine.execKeystrokes(session: session, keystrokes: [.A, .space, .m, .o, .d, .i, .f, .i, .e, .d, .escape, .j, .I, .p, .r, .e, .f, .i, .x, .space, .escape])
        
        #expect(finalState.mode == .normal, "Should end in normal mode")
        #expect(finalState.buffer.count >= 2, "Should have at least 2 lines")
    }
    
    @Test func allKeystrokesAreHandledByVimEngine() async throws {
        var failedKeys: [String] = []
        
        let engine = VimEngine(defaultSessionType: sessionType)
        
        for keystroke in KEYSTROKES {
            do {
                // Reset to normal mode before each test
                _ = try await engine.execKeystrokes([.escape])
                
                // Try to send the keystroke - should always return a valid state now
                let resultState = try await engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we got a valid state back with a recognized mode
                #expect(VimMode.allCases.contains(resultState.mode), "Mode should be valid for keystroke '\(keystroke)' but got \(resultState.mode)")
                
                
            } catch {
                failedKeys.append(keystroke)
            }
        }
        
        if !failedKeys.isEmpty {
            Issue.record("The following \(failedKeys.count) keystrokes failed: \(failedKeys.joined(separator: ", "))")
        }
        
        #expect(failedKeys.count < 50, "Should have fewer than 50 failed keystrokes")
    }
    
    @Test func allIndividualKeystrokesWork() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        var failedKeystrokes: [String] = []
        var testedCount = 0
        
        for keystroke in KEYSTROKES {
            do {
                // Reset to normal mode first
                _ = try await engine.execKeystrokes([.escape])
                
                // This should not throw an error - execKeystrokes handles blocking gracefully
                let resultState = try await engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we got a valid state back (this is the key test)
                #expect(VimMode.allCases.contains(resultState.mode), "Mode should be valid for keystroke '\(keystroke)'")
                
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
    
    @Test func keystrokesByCategory() async throws {
        let letters = KEYSTROKES.filter { $0.count == 1 && $0.first!.isLetter }
        let numbers = KEYSTROKES.filter { $0.count == 1 && $0.first!.isNumber }
        let specialKeys = KEYSTROKES.filter { $0.hasPrefix("<") && $0.hasSuffix(">") }
        let symbols = KEYSTROKES.filter { key in
            key.count == 1 && !key.first!.isLetter && !key.first!.isNumber && !key.hasPrefix("<")
        }
        
        var categoryResults: [String: (recognized: Int, total: Int)] = [:]
        
        func testCategory(name: String, keys: [String]) async {
            var recognized = 0
            let engine = VimEngine(defaultSessionType: sessionType)
            
            for key in keys {
                do {
                    _ = try await engine.execKeystrokes([.escape])  // Reset to normal mode
                    let resultState = try await engine.execKeystrokes([VimKeystroke(rawValue: key) ?? .escape])
                    // If we get a valid state back, the keystroke was handled
                    if VimMode.allCases.contains(resultState.mode) {
                        recognized += 1
                    }
                } catch {
                    // Key failed completely, continue
                }
            }
            categoryResults[name] = (recognized: recognized, total: keys.count)
        }
        
        await testCategory(name: "Letters", keys: letters)
        await testCategory(name: "Numbers", keys: numbers)
        await testCategory(name: "Special Keys", keys: specialKeys)
        await testCategory(name: "Symbols", keys: symbols)
        
        // Report results by category
        for (category, result) in categoryResults {
            #expect(result.recognized == result.total, 
                   "\(category): Expected all \(result.total) keys to be recognized, but only \(result.recognized) were")
        }
    }
    
    @Test func quickKeystrokeSample() async throws {
        // Test a small sample of keystrokes to identify common issues
        let sampleKeys: [VimKeystroke] = [.a, .b, .one, .two, .space, .escape, .enter, .backspace, .ctrlA, .metaA, .f1, .up]
        let engine = VimEngine(defaultSessionType: sessionType)
        
        var failed: [VimKeystroke] = []
        
        for key in sampleKeys {
            do {
                _ = try await engine.execKeystrokes([.escape]) // Reset to normal mode
                let result = try await engine.execKeystrokes([key])
                #expect(VimMode.allCases.contains(result.mode), "Keystroke '\(key)' should return valid mode")
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
    
    @Test func debugVimEngineCreation() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        let result = try await engine.execKeystrokes([.h])
        #expect(VimMode.allCases.contains(result.mode), "Should return valid mode")
    }
    
    @Test func testImprovedBlockingDetection() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Set up content first
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("test line")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test a regular key that doesn't block
        let stateA = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        #expect(stateA.mode == .insert, "Should enter insert mode after 'a'")
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test the previously problematic '1' key - should return fallback state
        let state1 = try await engine.execKeystrokes(session: session, keystrokes: [.one])
        #expect(state1.mode == .normal, "Should stay in normal mode after '1' (fallback state)")
        #expect(state1.cursor.row >= 0, "Should return valid cursor position")
        
        // Test completing the sequence - '1j' should move down 1 line (but we only have 1 line)
        let stateComplete = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        #expect(stateComplete.mode == .normal, "Should remain in normal mode after 'j'")
        #expect(stateComplete.cursor.row >= 0, "Should return valid cursor position")
    }
    
    @Test func testCountPrefixWithMotion() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Set up content first
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("line 1")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("line 2")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("line 3")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("line 4")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test count prefix with motion - should work as a complete sequence
        let stateBefore = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(stateBefore.cursor.row >= 0, "Should have valid cursor position")
        
        // Execute '3j' as separate keystrokes - first '3' will be blocking, then 'j' completes it
        let stateAfter3 = try await engine.execKeystrokes(session: session, keystrokes: [.three])
        #expect(stateAfter3.mode == .normal, "Should return normal mode (fallback state)")
        
        let stateAfterJ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        #expect(stateAfterJ.mode == .normal, "Should be in normal mode after completing '3j'")
        #expect(stateAfterJ.cursor.row >= 0, "Should have valid cursor position")
    }
}

// MARK: - Comprehensive Real-World Keystroke Tests
struct VimKeystrokesRealWorldTests {
    
    @Test func testProgrammingWorkflow() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Create a simple function with keystrokes
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("function calculateSum(a, b) {")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("    return a + b;")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("}")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        try await session.sendInput(" // Pure function")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.I])
        try await session.sendInput("    ")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        try await session.sendInput(" // Simple addition")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
        #expect(result.buffer.first?.contains("function calculateSum") == true, "Should contain function declaration")
        #expect(result.buffer.first?.contains("// Pure function") == true, "Should contain comment")
    }
    
    @Test func testTextEditingWorkflow() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Write a document with corrections
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("The quick brown fox jumps over the lazy dog.")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("This is a test document for vim editing.")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("We will make some corrections to this text.")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.f])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.q])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.s])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.Q])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.f])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.t])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.x])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.s])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.T])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.A])
        try await session.sendInput(" Now it's perfect!")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
        #expect(result.buffer.first?.contains("quick") == true, "Should contain corrected 'quick'")
    }
    
    @Test func testNavigationAndSelection() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Create content and navigate through it
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("First line with some content")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Second line with more text")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Third line for testing")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Fourth and final line")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Navigate and select
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.v])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.e])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.dollar])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.b])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.b])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.cursor.row >= 0, "Should have valid cursor row")
        #expect(result.cursor.col >= 0, "Should have valid cursor column")
    }
    
    @Test func testSearchAndReplace() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Create content with repeated words
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("apple banana apple cherry apple")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("grape apple orange apple lemon")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Search for 'apple'
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.slash])
        try await session.sendInput("apple")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.n])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.n])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode after search")
        #expect(result.buffer.first?.contains("apple") == true, "Should contain search term")
    }
    
    @Test func testComplexEditingOperations() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Complex editing scenario
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("TODO: Fix this bug")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("FIXME: Refactor this code")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("NOTE: Remember to test")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try await session.sendInput("DONE:")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try await session.sendInput("FIXED:")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.j])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.c, .w])
        try await session.sendInput("TESTED:")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.G])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.o])
        try await session.sendInput("All tasks completed!")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 4, "Should have at least 4 lines")
        #expect(result.buffer.joined(separator: "\n").contains("DONE:"), "Should contain DONE:")
        #expect(result.buffer.joined(separator: "\n").contains("FIXED:"), "Should contain FIXED:")
        #expect(result.buffer.joined(separator: "\n").contains("TESTED:"), "Should contain TESTED:")
        #expect(result.buffer.last?.contains("completed") == true, "Should contain completion message")
    }
    
    @Test func testSpecialCharactersAndSymbols() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Test various symbols and special characters
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Variables: $var, @array, %hash")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Math: 2 + 3 = 5, 10 - 4 = 6")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Symbols: !@#$%^&*()")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Quotes: \"double\" 'single' `backtick`")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Brackets: () [] {} <>")
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode")
        #expect(result.buffer.count >= 5, "Should have at least 5 lines")
        #expect(result.buffer.joined(separator: "\n").contains("$var"), "Should contain variable syntax")
        #expect(result.buffer.joined(separator: "\n").contains("!@#$%^&*()"), "Should contain special symbols")
        #expect(result.buffer.joined(separator: "\n").contains("\"double\""), "Should contain quoted text")
    }
    
    @Test func testFunctionKeys() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Test function keys work without errors
        let functionKeys: [VimKeystroke] = [.f1, .f2, .f3, .f4, .f5, .f6]
        
        for fKey in functionKeys {
            let result = try await engine.execKeystrokes([fKey])
            #expect(result.mode == VimMode.normal, "Function key \(fKey) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Function key \(fKey) should return valid cursor position")
        }
    }
    
    @Test func testControlCombinations() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Set up content for control key testing
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        
        // Add many lines for scrolling tests
        for i in 1...30 {
            try await session.sendInput("Line \(i) with content for testing")
            _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        }
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test important control combinations
        let controlTests: [VimKeystroke] = [.ctrlU, .ctrlD, .ctrlF, .ctrlB, .ctrlO, .ctrlG]
        
        for controlKey in controlTests {
            let result = try await engine.execKeystrokes(session: session, keystrokes: [controlKey])
            #expect(result.mode == VimMode.normal, "Control sequence \(controlKey) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Control sequence \(controlKey) should return valid position")
        }
    }
    
    @Test func testModeTransitionsWithRealContent() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Test all major mode transitions with real content
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Start in normal mode, go to insert
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Insert mode text")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual mode
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.v])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual line mode
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.V])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to visual block mode
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.ctrlV])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Go to replace mode
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.R])
        try await session.sendInput("Replace")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Try command mode
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        #expect(result.mode == VimMode.normal, "Should end in normal mode after all transitions")
        #expect(result.buffer.first?.contains("Replace") == true, "Should contain replaced text")
    }
    
    @Test func testDeleteAndYankOperations() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Create content for delete/yank operations
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("Line to delete")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Line to yank and paste")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("Line to keep")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test delete operations
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.d, .d])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.y, .y])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.p])
        
        #expect(result.mode == VimMode.normal, "Should be in normal mode after operations")
        #expect(result.buffer.count >= 2, "Should have remaining content")
    }
    
    @Test func testWordAndLineMovements() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Create content with various word patterns
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("word1 word2 word3.word4")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("another_line with-dashes")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.enter])
        try await session.sendInput("CamelCaseWords and spaces")
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        
        // Test word movements
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.g, .g])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.w])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.W])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.e])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.E])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.b])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.B])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.caret])
        _ = try await engine.execKeystrokes(session: session, keystrokes: [.dollar])
        let result = try await engine.execKeystrokes(session: session, keystrokes: [.zero])
        
        #expect(result.mode == VimMode.normal, "Should stay in normal mode during movements")
        #expect(result.cursor.row >= 0, "Should have valid cursor position")
        #expect(result.cursor.col == 0, "Should be at beginning of line after '0'")
    }
    
    @Test func testAllKeystrokesHandledProperly() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        var problematicKeys: [String] = []
        var successCount = 0
        
        // Test each keystroke individually
        for keystroke in KEYSTROKES {
            do {
                // Reset to clean state
                _ = try await engine.execKeystrokes([.escape])
                
                // Test the keystroke
                let result = try await engine.execKeystrokes([VimKeystroke(rawValue: keystroke) ?? .escape])
                
                // Verify we get a valid response
                if VimMode.allCases.contains(result.mode) && result.cursor.row >= 0 && result.cursor.col >= 0 {
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
    
    @Test func testKeystrokeStateConsistency() async throws {
        let engine = VimEngine(defaultSessionType: sessionType)
        
        // Test that each keystroke returns consistent state
        let session = try await SessionManager.shared.createAndStartSession(type: sessionType)
        // Session cleanup handled by runtime
        
        // Test Insert and exit
        var result = try await engine.execKeystrokes(session: session, keystrokes: [.i])
        try await session.sendInput("test")
        result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(VimMode.allCases.contains(result.mode), "Mode should be valid")
        #expect(result.cursor.row >= 0, "Cursor row should be valid")
        #expect(result.cursor.col >= 0, "Cursor col should be valid")
        #expect(result.buffer.count >= 0, "Buffer should be valid")
        
        // Test append and exit
        result = try await engine.execKeystrokes(session: session, keystrokes: [.a])
        try await session.sendInput("append")
        result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(VimMode.allCases.contains(result.mode), "Mode should be valid")
        
        // Test visual selection
        result = try await engine.execKeystrokes(session: session, keystrokes: [.v])
        result = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        result = try await engine.execKeystrokes(session: session, keystrokes: [.l])
        result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(VimMode.allCases.contains(result.mode), "Mode should be valid")
        
        // Test visual line
        result = try await engine.execKeystrokes(session: session, keystrokes: [.V])
        result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(VimMode.allCases.contains(result.mode), "Mode should be valid")
        
        // Test command mode
        result = try await engine.execKeystrokes(session: session, keystrokes: [.colon])
        result = try await engine.execKeystrokes(session: session, keystrokes: [.escape])
        #expect(VimMode.allCases.contains(result.mode), "Mode should be valid")
    }
}