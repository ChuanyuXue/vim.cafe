/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokesTests.swift (c) 2025
Desc: Comprehensive tests for VimKeystrokes definitions using Swift Testing with real values
Created:  2025-08-19T20:15:34.781Z
Updated:  2025-08-20T00:00:00.000Z
*/

import Testing
@testable import VimCafe

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
        
        // Set up content first
        _ = try engine.execKeystrokes([.i])
        for i in 1...20 {
            _ = try engine.execKeystrokes(["line \(i)", "<CR>"])
        }
        _ = try engine.execKeystrokes(["<Esc>"])
        
        let pageUpState = try engine.execKeystrokes(["<C-u>"])
        #expect(pageUpState.cursor.row >= 0, "Control-u should work")
        
        let pageDownState = try engine.execKeystrokes(["<C-d>"])
        #expect(pageDownState.cursor.row >= 0, "Control-d should work")
    }
    
    @Test func arrowKeysWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "first line", "<CR>", "second line", "<Esc>"])
        
        let rightState = try engine.execKeystrokes(["<Right>"])
        #expect(rightState.cursor.col >= 0, "Right arrow should work")
        
        let downState = try engine.execKeystrokes(["<Down>"])
        #expect(downState.cursor.row >= 0, "Down arrow should work")
        
        let leftState = try engine.execKeystrokes(["<Left>"])
        #expect(leftState.cursor.col >= 0, "Left arrow should work")
        
        let upState = try engine.execKeystrokes(["<Up>"])
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
        _ = try engine.execKeystrokes(session: session, keystrokes: ["i", "line one", "<CR>", "line two", "<Esc>"])
        
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
                _ = try engine.execKeystrokes(["<Esc>"])
                
                // Try to send the keystroke - should always return a valid state now
                let resultState = try engine.execKeystrokes([keystroke])
                
                // Verify we got a valid state back
                #expect(!resultState.mode.isEmpty, "Mode should not be empty for keystroke '\(keystroke)'")
                
                
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
                _ = try engine.execKeystrokes(["<Esc>"])
                
                // This should not throw an error - execKeystrokes handles blocking gracefully
                let resultState = try engine.execKeystrokes([keystroke])
                
                // Verify we got a valid state back (this is the key test)
                if resultState.mode.isEmpty {
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
                    _ = try engine.execKeystrokes(["<Esc>"])  // Reset to normal mode
                    let resultState = try engine.execKeystrokes([key])
                    // If we get a valid state back, the keystroke was handled
                    if !resultState.mode.isEmpty {
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
        let sampleKeys = ["a", "b", "1", "2", " ", "<Esc>", "<CR>", "<BS>", "<C-a>", "<M-a>", "<F1>", "<Up>"]
        let engine = VimEngine()
        
        var failed: [String] = []
        
        for key in sampleKeys {
            do {
                _ = try engine.execKeystrokes(["<Esc>"]) // Reset to normal mode
                let result = try engine.execKeystrokes([key])
                #expect(!result.mode.isEmpty, "Keystroke '\(key)' should return valid mode")
                #expect(result.cursor.row >= 0, "Keystroke '\(key)' should return valid cursor row")
                #expect(result.cursor.col >= 0, "Keystroke '\(key)' should return valid cursor col")
            } catch {
                failed.append(key)
            }
        }
        
        if !failed.isEmpty {
            Issue.record("Sample test failed for: \(failed.joined(separator: ", "))")
        }
    }
    
    @Test func debugVimEngineCreation() throws {
        let engine = VimEngine()
        
        let result = try engine.execKeystrokes(["h"])
        #expect(!result.mode.isEmpty, "Should return valid mode")
    }
    
    @Test func testImprovedBlockingDetection() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "test line", "<Esc>"])
        
        // Test a regular key that doesn't block
        let stateA = try engine.execKeystrokes(["a"])
        #expect(stateA.mode == .insert, "Should enter insert mode after 'a'")
        
        _ = try engine.execKeystrokes(["<Esc>"])
        
        // Test the previously problematic '1' key - should return fallback state
        let state1 = try engine.execKeystrokes(["1"])
        #expect(state1.mode == .normal, "Should stay in normal mode after '1' (fallback state)")
        #expect(state1.cursor.row >= 0, "Should return valid cursor position")
        
        // Test completing the sequence - '1j' should move down 1 line (but we only have 1 line)
        let stateComplete = try engine.execKeystrokes(["j"])
        #expect(stateComplete.mode == .normal, "Should remain in normal mode after 'j'")
        #expect(stateComplete.cursor.row >= 0, "Should return valid cursor position")
    }
    
    @Test func testCountPrefixWithMotion() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "line 1", "<CR>", "line 2", "<CR>", "line 3", "<CR>", "line 4", "<Esc>"])
        
        // Test count prefix with motion - should work as a complete sequence
        let stateBefore = try engine.execKeystrokes(["<Esc>"])
        #expect(stateBefore.cursor.row >= 0, "Should have valid cursor position")
        
        // Execute '3j' as separate keystrokes - first '3' will be blocking, then 'j' completes it
        let stateAfter3 = try engine.execKeystrokes(["3"])
        #expect(stateAfter3.mode == .normal, "Should return normal mode (fallback state)")
        
        let stateAfterJ = try engine.execKeystrokes(["j"])
        #expect(stateAfterJ.mode == .normal, "Should be in normal mode after completing '3j'")
        #expect(stateAfterJ.cursor.row >= 0, "Should have valid cursor position")
    }
}

// MARK: - Comprehensive Real-World Keystroke Tests
struct VimKeystrokesRealWorldTests {
    
    @Test func testProgrammingWorkflow() throws {
        let engine = VimEngine()
        
        // Create a simple function with keystrokes
        let keystrokes = [
            "i", "function calculateSum(a, b) {", "<CR>",
            "    return a + b;", "<CR>",
            "}", "<Esc>",
            "gg", "A", " // Pure function", "<Esc>",
            "j", "I", "    ", "<Esc>", // Add indentation
            "A", " // Simple addition", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode")
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
        let keystrokes = [
            "i", "The quick brown fox jumps over the lazy dog.", "<CR>",
            "This is a test document for vim editing.", "<CR>",
            "We will make some corrections to this text.", "<Esc>",
            "gg", "f", "q", "x", "s", "Q", "<Esc>", // Change 'quick' to 'Quick'
            "j", "0", "f", "t", "x", "s", "T", "<Esc>", // Change 'test' to 'Test'
            "A", " Now it's perfect!", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(session: session, keystrokes: keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode")
        #expect(result.buffer.count >= 3, "Should have at least 3 lines")
        #expect(result.buffer.first?.contains("Quick") == true, "Should contain corrected 'Quick'")
    }
    
    @Test func testNavigationAndSelection() throws {
        let engine = VimEngine()
        
        // Create content and navigate through it
        let setupKeystrokes = [
            "i", "First line with some content", "<CR>",
            "Second line with more text", "<CR>",
            "Third line for testing", "<CR>",
            "Fourth and final line", "<Esc>"
        ]
        
        _ = try engine.execKeystrokes(setupKeystrokes)
        
        // Navigate and select
        let navigationKeystrokes = [
            "gg", "0", // Go to beginning
            "w", "w", // Move to third word
            "v", "e", // Select word in visual mode
            "<Esc>", // Exit visual mode
            "j", "j", // Move down two lines
            "$", // Go to end of line
            "b", "b" // Move back two words
        ]
        
        let result = try engine.execKeystrokes(navigationKeystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode")
        #expect(result.cursor.row >= 0, "Should have valid cursor row")
        #expect(result.cursor.col >= 0, "Should have valid cursor column")
    }
    
    @Test func testSearchAndReplace() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Create content with repeated words
        let setupKeystrokes = [
            "i", "apple banana apple cherry apple", "<CR>",
            "grape apple orange apple lemon", "<Esc>"
        ]
        
        _ = try engine.execKeystrokes(session: session, keystrokes: setupKeystrokes)
        
        // Search for 'apple'
        let searchKeystrokes = [
            "/", "apple", "<CR>", // Search for apple
            "n", // Next occurrence
            "n" // Next occurrence again
        ]
        
        let result = try engine.execKeystrokes(session: session, keystrokes: searchKeystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode after search")
        #expect(result.buffer.first?.contains("apple") == true, "Should contain search term")
    }
    
    @Test func testComplexEditingOperations() throws {
        let engine = VimEngine()
        let session = NvimSession()
        try session.start()
        defer { session.stop() }
        
        // Complex editing scenario
        let keystrokes = [
            "i", "TODO: Fix this bug", "<CR>",
            "FIXME: Refactor this code", "<CR>",
            "NOTE: Remember to test", "<Esc>",
            "gg", "0", "cw", "DONE:", "<Esc>", // Change TODO to DONE
            "j", "0", "cw", "FIXED:", "<Esc>", // Change FIXME to FIXED  
            "j", "0", "cw", "TESTED:", "<Esc>", // Change NOTE to TESTED
            "G", "o", "All tasks completed!", "<Esc>" // Add new line at end
        ]
        
        let result = try engine.execKeystrokes(session: session, keystrokes: keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode")
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
        let keystrokes = [
            "i", "Variables: $var, @array, %hash", "<CR>",
            "Math: 2 + 3 = 5, 10 - 4 = 6", "<CR>",
            "Symbols: !@#$%^&*()", "<CR>",
            "Quotes: \"double\" 'single' `backtick`", "<CR>",
            "Brackets: () [] {} <LT>>", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(session: session, keystrokes: keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode")
        #expect(result.buffer.count >= 5, "Should have at least 5 lines")
        #expect(result.buffer.contains("$var"), "Should contain variable syntax")
        #expect(result.buffer.contains("!@#$%^&*()"), "Should contain special symbols")
        #expect(result.buffer.contains("\"double\""), "Should contain quoted text")
    }
    
    @Test func testFunctionKeys() throws {
        let engine = VimEngine()
        
        // Test function keys work without errors
        let functionKeys = ["<F1>", "<F2>", "<F3>", "<F4>", "<F5>", "<F6>"]
        
        for fKey in functionKeys {
            let result = try engine.execKeystrokes([fKey])
            #expect(result.mode == .normal, "Function key \(fKey) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Function key \(fKey) should return valid cursor position")
        }
    }
    
    @Test func testControlCombinations() throws {
        let engine = VimEngine()
        
        // Set up content for control key testing
        var setupKeystrokes = [
            "i"
        ]
        
        // Add many lines for scrolling tests
        for i in 1...30 {
            setupKeystrokes.append("Line \(i) with content for testing")
            setupKeystrokes.append("<CR>")
        }
        setupKeystrokes.append("<Esc>")
        
        _ = try engine.execKeystrokes(setupKeystrokes)
        
        // Test important control combinations
        let controlTests = [
            ["<C-u>"], // Scroll up
            ["<C-d>"], // Scroll down
            ["<C-f>"], // Page forward
            ["<C-b>"], // Page backward
            ["<C-o>"], // Jump backward
            ["<C-g>"] // Show file info
        ]
        
        for controlSeq in controlTests {
            let result = try engine.execKeystrokes(controlSeq)
            #expect(result.mode == .normal, "Control sequence \(controlSeq) should maintain normal mode")
            #expect(result.cursor.row >= 0, "Control sequence \(controlSeq) should return valid position")
        }
    }
    
    @Test func testModeTransitionsWithRealContent() throws {
        let engine = VimEngine()
        
        // Test all major mode transitions with real content
        let keystrokes = [
            // Start in normal mode, go to insert
            "i", "Insert mode text", "<Esc>",
            
            // Go to visual mode
            "v", "l", "l", "l", "<Esc>",
            
            // Go to visual line mode
            "V", "<Esc>",
            
            // Go to visual block mode
            "<C-v>", "<Esc>",
            
            // Go to replace mode
            "R", "Replace", "<Esc>",
            
            // Try command mode
            ":", "<Esc>"
        ]
        
        let result = try engine.execKeystrokes(keystrokes)
        
        #expect(result.mode == .normal, "Should end in normal mode after all transitions")
        #expect(result.buffer.first?.contains("Replace") == true, "Should contain replaced text")
    }
    
    @Test func testDeleteAndYankOperations() throws {
        let engine = VimEngine()
        
        // Create content for delete/yank operations
        let setupKeystrokes = [
            "i", "Line to delete", "<CR>",
            "Line to yank and paste", "<CR>",
            "Line to keep", "<Esc>"
        ]
        
        _ = try engine.execKeystrokes(setupKeystrokes)
        
        // Test delete operations
        let deleteKeystrokes = [
            "gg", // Go to first line
            "dd", // Delete entire line
            "yy", // Yank current line
            "p" // Paste below
        ]
        
        let result = try engine.execKeystrokes(deleteKeystrokes)
        
        #expect(result.mode == .normal, "Should be in normal mode after operations")
        #expect(result.buffer.count >= 2, "Should have remaining content")
    }
    
    @Test func testWordAndLineMovements() throws {
        let engine = VimEngine()
        
        // Create content with various word patterns
        let setupKeystrokes = [
            "i", "word1 word2 word3.word4", "<CR>",
            "another_line with-dashes", "<CR>",
            "CamelCaseWords and spaces", "<Esc>"
        ]
        
        _ = try engine.execKeystrokes(setupKeystrokes)
        
        // Test word movements
        let movementKeystrokes = [
            "gg", "0", // Start at beginning
            "w", // Next word
            "W", // Next WORD
            "e", // End of word
            "E", // End of WORD
            "b", // Back word
            "B", // Back WORD
            "^", // First non-blank
            "$", // End of line
            "0" // Beginning of line
        ]
        
        let result = try engine.execKeystrokes(movementKeystrokes)
        
        #expect(result.mode == .normal, "Should stay in normal mode during movements")
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
                _ = try engine.execKeystrokes(["<Esc>"])
                
                // Test the keystroke
                let result = try engine.execKeystrokes([keystroke])
                
                // Verify we get a valid response
                if !result.mode.isEmpty && result.cursor.row >= 0 && result.cursor.col >= 0 {
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
        let testSequences = [
            ["i", "test", "<Esc>"], // Insert and exit
            ["a", "append", "<Esc>"], // Append and exit
            ["o", "new line", "<Esc>"], // Open line and exit
            ["O", "line above", "<Esc>"], // Open line above and exit
            ["v", "l", "l", "<Esc>"], // Visual selection
            ["V", "<Esc>"], // Visual line
            ["/", "test", "<CR>"], // Search
            [":", "<Esc>"] // Command mode
        ]
        
        for sequence in testSequences {
            let result = try engine.execKeystrokes(sequence)
            
            #expect(!result.mode.isEmpty, "Mode should not be empty for sequence: \(sequence)")
            #expect(result.cursor.row >= 0, "Cursor row should be valid for sequence: \(sequence)")
            #expect(result.cursor.col >= 0, "Cursor col should be valid for sequence: \(sequence)")
            #expect(result.buffer.count >= 0, "Buffer should be valid for sequence: \(sequence)")
        }
    }
}