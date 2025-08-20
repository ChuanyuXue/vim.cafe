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
    case operatorPending = "no"
    case operatorPendingCharwise = "nov"
    case operatorPendingLinewise = "noV"
    case operatorPendingBlockwise = "no\u{16}"
    case normalInsertMode = "niI"
    case normalReplaceMode = "niR"
    case normalVirtualReplaceMode = "niV"
    case normalTerminal = "nt"
    case normalTerminalTemp = "ntT"
    case visual = "v"
    case visualSelect = "vs"
    case visualLine = "V"
    case visualLineSelect = "Vs"
    case visualBlock = "\u{16}"
    case visualBlockSelect = "\u{16}s"
    case selectCharacter = "s"
    case selectLine = "S"
    case selectBlock = "\u{13}"
    case insert = "i"
    case insertCompletion = "ic"
    case insertCompletionX = "ix"
    case replace = "R"
    case replaceCompletion = "Rc"
    case replaceCompletionX = "Rx"
    case virtualReplace = "Rv"
    case virtualReplaceCompletion = "Rvc"
    case virtualReplaceCompletionX = "Rvx"
    case command = "c"
    case commandOverstrike = "cr"
    case exMode = "cv"
    case exModeOverstrike = "cvr"
    case hitEnter = "r"
    case more = "rm"
    case confirm = "r?"
    case shell = "!"
    case terminal = "t"
    
    var shortMode: String {
        switch self {
        case .normal, .operatorPending, .operatorPendingCharwise, .operatorPendingLinewise, .operatorPendingBlockwise,
             .normalInsertMode, .normalReplaceMode, .normalVirtualReplaceMode, .normalTerminal, .normalTerminalTemp:
            return "n"
        case .visual, .visualSelect, .visualLine, .visualLineSelect, .visualBlock, .visualBlockSelect:
            return "v"
        case .selectCharacter, .selectLine, .selectBlock:
            return "s"
        case .insert, .insertCompletion, .insertCompletionX:
            return "i"
        case .replace, .replaceCompletion, .replaceCompletionX, .virtualReplace, .virtualReplaceCompletion, .virtualReplaceCompletionX:
            return "R"
        case .command, .commandOverstrike, .exMode, .exModeOverstrike:
            return "c"
        case .hitEnter, .more, .confirm:
            return "r"
        case .shell:
            return "!"
        case .terminal:
            return "t"
        }
    }
}

struct VimCursor: Hashable {
    let row: Int
    let col: Int
}
