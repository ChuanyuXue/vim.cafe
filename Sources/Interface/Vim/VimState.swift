/*
Author: <Chuanyu> (skewcy@gmail.com)
VimState.swift (c) 2025
Desc: description
Created:  2025-08-17T20:15:34.781Z
*/

import Foundation

/**
Minimum state to describe the visible state of vim.
There might be hidden states, e.g., registers, previous keystrokes, etc.
*/
struct VimState: Hashable {
    let buffer: [String]
    let cursorRow: Int
    let cursorCol: Int
    let mode: String
    
    static let COMMON_MODES: [String] = [
        "n",   // Normal
        "i",   // Insert
        "v",   // Visual by character
        "V",   // Visual by line
        "c",   // Command-line editing
        "R"    // Replace
    ]
}
