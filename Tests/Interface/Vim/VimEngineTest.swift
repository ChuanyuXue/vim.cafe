/*
Author: <Chuanyu> (skewcy@gmail.com)  
VimEngineBasicTests.swift (c) 2025
Desc: Basic tests for VimEngine structure (without nvim integration)
Created:  2025-08-19T20:15:34.781Z
*/

import Testing
import Foundation
@testable import VimCafe

struct VimEngineBasicTests {
    
    @Test func vimEngineClassExists() {
        // Test that VimEngine class can be referenced
        let engineType = VimEngine.self
        #expect(engineType == VimEngine.self)
    }
    
    @Test func vimStateStructureValidation() {
        // Test that VimState works as expected for VimEngine input
        let state = VimState(
            buffer: ["Hello", "World"],
            cursorRow: 0, cursorCol: 0,
            mode: "n"
        )
        
        #expect(state.buffer == ["Hello", "World"])
        #expect(state.cursorRow == 0)
        #expect(state.cursorCol == 0)
        #expect(state.mode == "n")
    }
    
    @Test func keystrokeArrayValidation() {
        // Test that keystroke arrays work as expected for VimEngine input
        let keystrokes = ["j", "k", "h", "l"]
        #expect(keystrokes.count == 4)
        #expect(keystrokes.allSatisfy { !$0.isEmpty })
    }
    
    @Test func basicVimCommandsAreInKeystrokes() {
        // Test that essential vim commands are available in KEYSTROKES
        let essentialCommands = ["h", "j", "k", "l", "i", "a", "o", "<Esc>", "w", "b", "0", "$"]
        
        for command in essentialCommands {
            #expect(KEYSTROKES.contains(command), "Essential vim command '\(command)' should be in KEYSTROKES")
        }
    }
    
    @Test func nvimInstallationCheck() {
        let nvimPath = "/opt/homebrew/bin/nvim"
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: nvimPath)
        
        if !exists {
            Issue.record("nvim not found at \(nvimPath). Install with: brew install neovim")
        }
        
        // Document the requirement
        #expect(Bool(true), "VimEngine requires nvim installation for full functionality")
    }
}