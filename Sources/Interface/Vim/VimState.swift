/*
Author: <Chuanyu> (skewcy@gmail.com)
VimState.swift (c) 2025
Desc: description
Created:  2025-08-17T20:15:34.781Z
*/

import Foundation

struct VimState: Hashable {
    let buffer: [String]
    let cursor: VimCursor
    let mode: VimMode
}

enum VimMode: String, CaseIterable {
    case normal = "n"
    case insert = "i"
    case visual = "v"
    case visualLine = "V"
    case command = "c"
    case replace = "R"
}

struct VimCursor: Hashable {
    let row: Int
    let col: Int
}
