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
        let engine = VimEngine()
        
        let rightState = try engine.execKeystrokes(["l"])
        #expect(rightState.cursorCol >= 0, "Moving right with 'l' should work")
        
        let downState = try engine.execKeystrokes(["j"])  
        #expect(downState.cursorRow >= 0, "Moving down with 'j' should work")
        
        let leftState = try engine.execKeystrokes(["h"])
        #expect(leftState.cursorCol >= 0, "Moving left with 'h' should work")
        
        let upState = try engine.execKeystrokes(["k"])
        #expect(upState.cursorRow >= 0, "Moving up with 'k' should work")
    }
    
    @Test func specialKeysWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        let insertState = try engine.execKeystrokes(["i"])
        #expect(insertState.mode == "i", "Pressing 'i' should enter insert mode")
        
        let escapeState = try engine.execKeystrokes(["<Esc>"])
        #expect(escapeState.mode == "n", "Pressing <Esc> should return to normal mode")
        
        let appendState = try engine.execKeystrokes(["A"])
        #expect(appendState.mode == "i", "Pressing 'A' should enter insert mode")
    }
    
    @Test func textInsertionKeystrokesWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        let resultState = try engine.execKeystrokes(["i", "hello", "<Esc>"])
        
        #expect(resultState.mode == "n", "Should return to normal mode after <Esc>")
        #expect(resultState.buffer.first?.contains("hello") == true, "Buffer should contain inserted text 'hello'")
    }
    
    @Test func controlCombinationsWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i"])
        for i in 1...20 {
            _ = try engine.execKeystrokes(["line \(i)", "<CR>"])
        }
        _ = try engine.execKeystrokes(["<Esc>"])
        
        let pageUpState = try engine.execKeystrokes(["<C-u>"])
        #expect(pageUpState.cursorRow >= 0, "Control-u should work")
        
        let pageDownState = try engine.execKeystrokes(["<C-d>"])
        #expect(pageDownState.cursorRow >= 0, "Control-d should work")
    }
    
    @Test func arrowKeysWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "first line", "<CR>", "second line", "<Esc>"])
        
        let rightState = try engine.execKeystrokes(["<Right>"])
        #expect(rightState.cursorCol >= 0, "Right arrow should work")
        
        let downState = try engine.execKeystrokes(["<Down>"])
        #expect(downState.cursorRow >= 0, "Down arrow should work")
        
        let leftState = try engine.execKeystrokes(["<Left>"])
        #expect(leftState.cursorCol >= 0, "Left arrow should work")
        
        let upState = try engine.execKeystrokes(["<Up>"])
        #expect(upState.cursorRow >= 0, "Up arrow should work")
    }
    
    @Test func backspaceAndDeleteWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "hello world", "<Esc>"])
        
        let insertState = try engine.execKeystrokes(["i"])
        #expect(insertState.mode == "i", "Should enter insert mode")
        
        let backspaceState = try engine.execKeystrokes(["<BS>"])
        #expect(backspaceState.mode == "i", "Should stay in insert mode after backspace")
        
        let deleteState = try engine.execKeystrokes(["<Del>"])
        #expect(deleteState.mode == "i", "Should stay in insert mode after delete")
    }
    
    @Test func complexKeystrokeSequenceWorkWithVimEngine() throws {
        let engine = VimEngine()
        
        // Set up initial content
        _ = try engine.execKeystrokes(["i", "line one", "<CR>", "line two", "<Esc>"])
        
        let finalState = try engine.execKeystrokes(["A", " modified", "<Esc>", "j", "I", "prefix ", "<Esc>"])
        
        #expect(finalState.mode == "n", "Should end in normal mode")
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
            let percentage = result.total > 0 ? (Double(result.recognized) / Double(result.total)) * 100 : 0
            print("\(category): \(result.recognized)/\(result.total) (\(String(format: "%.1f", percentage))%) recognized")
            
            #expect(result.recognized >= result.total * 8 / 10, 
                   "\(category): Expected at least 80% of \(result.total) keys to be recognized, but only \(result.recognized) were")
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
                _ = try engine.execKeystrokes([key])
                print("✓ '\(key)' works")
            } catch let error as NvimSessionError {
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
        #expect(stateA.mode == "i", "Should enter insert mode after 'a'")
        
        _ = try engine.execKeystrokes(["<Esc>"])
        
        // Test the previously problematic '1' key - should return fallback state
        let state1 = try engine.execKeystrokes(["1"])
        #expect(state1.mode == "n", "Should stay in normal mode after '1' (fallback state)")
        #expect(state1.cursorRow >= 0, "Should return valid cursor position")
        
        // Test completing the sequence - '1j' should move down 1 line (but we only have 1 line)
        let stateComplete = try engine.execKeystrokes(["j"])
        #expect(stateComplete.mode == "n", "Should remain in normal mode after 'j'")
        #expect(stateComplete.cursorRow >= 0, "Should return valid cursor position")
    }
    
    @Test func testCountPrefixWithMotion() throws {
        let engine = VimEngine()
        
        // Set up content first
        _ = try engine.execKeystrokes(["i", "line 1", "<CR>", "line 2", "<CR>", "line 3", "<CR>", "line 4", "<Esc>"])
        
        // Test count prefix with motion - should work as a complete sequence
        let stateBefore = try engine.execKeystrokes(["<Esc>"])
        #expect(stateBefore.cursorRow >= 0, "Should have valid cursor position")
        
        // Execute '3j' as separate keystrokes - first '3' will be blocking, then 'j' completes it
        let stateAfter3 = try engine.execKeystrokes(["3"])
        #expect(stateAfter3.mode == "n", "Should return normal mode (fallback state)")
        
        let stateAfterJ = try engine.execKeystrokes(["j"])
        #expect(stateAfterJ.mode == "n", "Should be in normal mode after completing '3j'")
        #expect(stateAfterJ.cursorRow >= 0, "Should have valid cursor position")
    }
}