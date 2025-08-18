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
    let cursor: Point
    let mode: VimMode

    struct Point: Hashable {
        let row: Int
        let col: Int
    }

    enum VimMode: Hashable {
        case normal
        case insert
        case visual
        case command
        case replace
    }
}
