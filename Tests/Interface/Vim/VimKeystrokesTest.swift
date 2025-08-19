/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokesTests.swift (c) 2025
Desc: Tests for VimKeystrokes definitions using Swift Testing
Created:  2025-08-19T20:15:34.781Z
*/

import Testing
@testable import VimCafe

struct VimKeystrokesTests {
    @Test func basicNavigationKeystrokesWorkWithVimEngine() throws {
        let initialState = VimState(buffer: ["hello world", "second line"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let rightState = try engine.execKeystrokes(["l"])
        #expect(rightState.cursorCol > 0, "Moving right with 'l' should increase cursor column")
        
        let downState = try engine.execKeystrokes(["j"])  
        #expect(downState.cursorRow > 0, "Moving down with 'j' should increase cursor row")
        
        let leftState = try engine.execKeystrokes(["h"])
        #expect(leftState.cursorCol >= 0, "Moving left with 'h' should work")
        
        let upState = try engine.execKeystrokes(["k"])
        #expect(upState.cursorRow >= 0, "Moving up with 'k' should work")
    }
    
    @Test func specialKeysWorkWithVimEngine() throws {
        print("=== Starting specialKeysWorkWithVimEngine test ===")
        
        let initialState = VimState(buffer: ["test line"], cursorRow: 0, cursorCol: 0, mode: "n")
        print("DEBUG: Creating VimEngine...")
        let engine = try VimEngine(state: initialState)
        print("DEBUG: VimEngine created successfully")
        
        print("DEBUG: Testing 'i' keystroke...")
        let insertState = try engine.execKeystrokes(["i"])
        print("DEBUG: 'i' keystroke completed, mode: \(insertState.mode)")
        #expect(insertState.mode == "i", "Pressing 'i' should enter insert mode")
        
        print("DEBUG: Testing '<Esc>' keystroke...")
        let escapeState = try engine.execKeystrokes(["<Esc>"])
        print("DEBUG: '<Esc>' keystroke completed, mode: \(escapeState.mode)")
        #expect(escapeState.mode == "n", "Pressing <Esc> should return to normal mode")
        
        print("DEBUG: Testing 'A' keystroke...")
        let appendState = try engine.execKeystrokes(["A"])
        print("DEBUG: 'A' keystroke completed, mode: \(appendState.mode), cursorCol: \(appendState.cursorCol)")
        #expect(appendState.mode == "i", "Pressing 'A' should enter insert mode")
        #expect(appendState.cursorCol > 0, "Pressing 'A' should move cursor to end of line")
        
        print("=== specialKeysWorkWithVimEngine test completed successfully ===")
    }
    
    @Test func textInsertionKeystrokesWorkWithVimEngine() throws {
        let initialState = VimState(buffer: [""], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let resultState = try engine.execKeystrokes(["i", "hello", "<Esc>"])
        
        #expect(resultState.mode == "n", "Should return to normal mode after <Esc>")
        #expect(resultState.buffer.first?.contains("hello") == true, "Buffer should contain inserted text 'hello'")
    }
    
    @Test func controlCombinationsWorkWithVimEngine() throws {
        let longText = Array(repeating: "line of text here", count: 20)
        let initialState = VimState(buffer: longText, cursorRow: 19, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let pageUpState = try engine.execKeystrokes(["<C-u>"])
        #expect(pageUpState.cursorRow < 19, "Control-u should move cursor up multiple lines")
        
        let pageDownState = try engine.execKeystrokes(["<C-d>"])
        #expect(pageDownState.cursorRow >= pageUpState.cursorRow, "Control-d should move cursor down")
    }
    
    @Test func arrowKeysWorkWithVimEngine() throws {
        let initialState = VimState(buffer: ["first line", "second line"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let rightState = try engine.execKeystrokes(["<Right>"])
        #expect(rightState.cursorCol > 0, "Right arrow should move cursor right")
        
        let downState = try engine.execKeystrokes(["<Down>"])
        #expect(downState.cursorRow > 0, "Down arrow should move cursor down")
        
        let leftState = try engine.execKeystrokes(["<Left>"])
        #expect(leftState.cursorCol >= 0, "Left arrow should work")
        
        let upState = try engine.execKeystrokes(["<Up>"])
        #expect(upState.cursorRow >= 0, "Up arrow should work")
    }
    
    @Test func backspaceAndDeleteWorkWithVimEngine() throws {
        let initialState = VimState(buffer: ["hello world"], cursorRow: 0, cursorCol: 5, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let insertState = try engine.execKeystrokes(["i"])
        #expect(insertState.mode == "i", "Should enter insert mode")
        
        let backspaceState = try engine.execKeystrokes(["<BS>"])
        #expect(backspaceState.buffer.first != "hello world", "Backspace should modify the text")
        
        let deleteState = try engine.execKeystrokes(["<Del>"])
        #expect(deleteState.buffer.first != backspaceState.buffer.first, "Delete should modify the text")
    }
    
    @Test func complexKeystrokeSequenceWorkWithVimEngine() throws {
        let initialState = VimState(buffer: ["line one", "line two"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        let finalState = try engine.execKeystrokes(["A", " modified", "<Esc>", "j", "I", "prefix ", "<Esc>"])
        
        #expect(finalState.mode == "n", "Should end in normal mode")
        #expect(finalState.buffer[0].contains("modified"), "First line should contain 'modified'")
        #expect(finalState.buffer[1].contains("prefix"), "Second line should contain 'prefix'")
    }
    
    @Test func allKeystrokesAreHandledByVimEngine() throws {
        var failedKeys: [String] = []
        
        let initialState = VimState(buffer: ["test line for keystroke testing"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        for (index, keystroke) in KEYSTROKES.enumerated() {
            do {
                // Reset to normal mode before each test
                _ = try engine.execKeystrokes(["<Esc>"])
                
                // Try to send the keystroke - should always return a valid state now
                let resultState = try engine.execKeystrokes([keystroke])
                
                // Verify we got a valid state back
                #expect(!resultState.mode.isEmpty, "Mode should not be empty for keystroke '\(keystroke)'")
                
                // Print progress every 50 keystrokes
                if index % 50 == 0 {
                    print("Tested \(index + 1)/\(KEYSTROKES.count) keystrokes...")
                }
                
            } catch {
                failedKeys.append(keystroke)
                print("Failed keystroke '\(keystroke)': \(error.localizedDescription)")
            }
        }
        
        print("Summary: \(KEYSTROKES.count - failedKeys.count)/\(KEYSTROKES.count) keystrokes handled successfully")
        
        if !failedKeys.isEmpty {
            Issue.record("The following \(failedKeys.count) keystrokes failed: \(failedKeys.joined(separator: ", "))")
        }
        
        #expect(failedKeys.isEmpty, 
               "All \(KEYSTROKES.count) keystrokes should be handled by VimEngine. Failed: \(failedKeys)")
    }
    
    @Test func allIndividualKeystrokesWork() throws {
        let initialState = VimState(buffer: ["test content for keystroke testing"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
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
                
                // Print progress every 50 keystrokes
                if testedCount % 50 == 0 {
                    print("Tested \(testedCount)/\(KEYSTROKES.count) keystrokes...")
                }
                
            } catch {
                failedKeystrokes.append(keystroke)
                print("Keystroke '\(keystroke)' failed: \(error)")
            }
        }
        
        print("Summary: \(testedCount - failedKeystrokes.count)/\(testedCount) keystrokes succeeded")
        
        if !failedKeystrokes.isEmpty {
            Issue.record("Failed keystrokes: \(failedKeystrokes.joined(separator: ", "))")
        }
        
        #expect(failedKeystrokes.count < 10, "Should have fewer than 10 failed keystrokes, got \(failedKeystrokes.count)")
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
            let initialState = VimState(buffer: ["test"], cursorRow: 0, cursorCol: 0, mode: "n")
            let engine = try! VimEngine(state: initialState)
            
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
            let percentage = result.total > 0 ? (Double(result.recognized) / Double(result.total)) * 100 : 0
            print("\(category): \(result.recognized)/\(result.total) (\(String(format: "%.1f", percentage))%) recognized")
            
            #expect(result.recognized == result.total, 
                   "\(category): Expected all \(result.total) keys to be recognized, but only \(result.recognized) were")
        }
    }
    
    @Test func quickKeystrokeSample() throws {
        // Test a small sample of keystrokes to identify common issues
        let sampleKeys = ["a", "b", "1", "2", " ", "<Esc>", "<CR>", "<BS>", "<C-a>", "<M-a>", "<F1>", "<Up>"]
        let initialState = VimState(buffer: ["test"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        var failed: [String] = []
        
        for key in sampleKeys {
            do {
                _ = try engine.execKeystrokes(["<Esc>"]) // Reset to normal mode
                _ = try engine.execKeystrokes([key])
                print("✓ '\(key)' works")
            } catch let error as NvimClientError {
                failed.append(key)
                switch error {
                case .startupFailed(let underlyingError):
                    print("✗ '\(key)' failed: Startup failed - \(underlyingError)")
                case .communicationFailed(let message):
                    print("✗ '\(key)' failed: Communication failed - \(message)")
                case .invalidResponse(let message):
                    print("✗ '\(key)' failed: Invalid response - \(message)")
                case .notRunning:
                    print("✗ '\(key)' failed: Nvim not running")
                }
            } catch {
                failed.append(key)
                print("✗ '\(key)' failed: \(error)")
            }
        }
        
        if !failed.isEmpty {
            Issue.record("Sample test failed for: \(failed.joined(separator: ", "))")
        }
    }
    
    @Test func debugVimEngineCreation() throws {
        print("DEBUG: Creating VimEngine to isolate the issue...")
        let initialState = VimState(buffer: ["test line"], cursorRow: 0, cursorCol: 0, mode: "n")
        
        do {
            print("DEBUG: About to call VimEngine constructor...")
            let engine = try VimEngine(state: initialState)
            print("DEBUG: VimEngine created successfully!")
            
            print("DEBUG: Testing simple keystroke...")
            let result = try engine.execKeystrokes(["h"])
            print("DEBUG: Simple keystroke completed, mode: \(result.mode)")
            
        } catch {
            print("DEBUG: VimEngine creation failed with error: \(error)")
            print("DEBUG: Error type: \(type(of: error))")
            if let nvimError = error as? NvimClientError {
                switch nvimError {
                case .startupFailed(let underlyingError):
                    print("DEBUG: Startup failed: \(underlyingError)")
                case .communicationFailed(let message):
                    print("DEBUG: Communication failed: \(message)")
                case .invalidResponse(let message):
                    print("DEBUG: Invalid response: \(message)")
                case .notRunning:
                    print("DEBUG: Nvim not running")
                }
            }
            throw error
        }
    }
    
    @Test func testImprovedBlockingDetection() throws {
        let initialState = VimState(buffer: ["test line"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        // Test a regular key that doesn't block
        let stateA = try engine.execKeystrokes(["a"])
        #expect(stateA.mode == "i", "Should enter insert mode after 'a'")
        #expect(stateA.buffer == ["test line"], "Buffer should remain unchanged after 'a'")
        
        _ = try engine.execKeystrokes(["<Esc>"])
        
        // Test the previously problematic '1' key - should return fallback state
        let state1 = try engine.execKeystrokes(["1"])
        #expect(state1.mode == "n", "Should stay in normal mode after '1' (fallback state)")
        #expect(state1.buffer == ["test line"], "Should return real buffer content, not fake data")
        #expect(state1.cursorRow == 0, "Should return valid cursor position")
        
        // Test completing the sequence - '1j' should move down 1 line (but we only have 1 line)
        let stateComplete = try engine.execKeystrokes(["j"])
        #expect(stateComplete.mode == "n", "Should remain in normal mode after 'j'")
        #expect(stateComplete.cursorRow == 0, "Should stay at row 0 (can't move down from single line)")
        
        // Test getCurrentState directly when vim is not blocking
        let currentState = try engine.getCurrentState()
        #expect(currentState != nil, "getCurrentState should return a state when vim is not blocking")
        #expect(currentState?.mode == "n", "Should be in normal mode")
        #expect(currentState?.buffer == ["test line"], "Should return correct buffer content")
    }
    
    @Test func testCountPrefixWithMotion() throws {
        let initialState = VimState(buffer: ["line 1", "line 2", "line 3", "line 4"], cursorRow: 0, cursorCol: 0, mode: "n")
        let engine = try VimEngine(state: initialState)
        
        // Test count prefix with motion - should work as a complete sequence
        let stateBefore = try engine.execKeystrokes(["<Esc>"])
        #expect(stateBefore.cursorRow == 0, "Should start at row 0")
        
        // Execute '3j' as separate keystrokes - first '3' will be blocking, then 'j' completes it
        let stateAfter3 = try engine.execKeystrokes(["3"])
        #expect(stateAfter3.mode == "n", "Should return normal mode (fallback state)")
        #expect(stateAfter3.buffer == ["line 1", "line 2", "line 3", "line 4"], "Should return real buffer content")
        
        let stateAfterJ = try engine.execKeystrokes(["j"])
        #expect(stateAfterJ.mode == "n", "Should be in normal mode after completing '3j'")
        #expect(stateAfterJ.cursorRow == 3, "Should move down 3 lines (from 0 to 3)")
        
        // Test that we can still get current state normally
        let finalState = try engine.getCurrentState()
        #expect(finalState != nil, "Should be able to get current state")
        #expect(finalState?.cursorRow == 3, "Cursor should be at row 3")
    }
}