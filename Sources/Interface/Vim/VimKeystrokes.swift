/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokes.swift (c) 2025
Desc: Simple keystroke definitions for nvim RPC
Created:  2025-08-17T20:15:34.781Z
*/

import Foundation

enum VimKeystroke: String, CaseIterable {
    // Letters
    case a = "a", b = "b", c = "c", d = "d", e = "e", f = "f", g = "g", h = "h", i = "i", j = "j", k = "k", l = "l", m = "m"
    case n = "n", o = "o", p = "p", q = "q", r = "r", s = "s", t = "t", u = "u", v = "v", w = "w", x = "x", y = "y", z = "z"
    case A = "A", B = "B", C = "C", D = "D", E = "E", F = "F", G = "G", H = "H", I = "I", J = "J", K = "K", L = "L", M = "M"
    case N = "N", O = "O", P = "P", Q = "Q", R = "R", S = "S", T = "T", U = "U", V = "V", W = "W", X = "X", Y = "Y", Z = "Z"
    
    // Numbers
    case zero = "0", one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    
    // Symbols
    case space = " ", exclamation = "!", at = "@", hash = "#", dollar = "$", percent = "%", caret = "^", ampersand = "&"
    case asterisk = "*", leftParen = "(", rightParen = ")", minus = "-", underscore = "_", equals = "=", plus = "+"
    case leftBracket = "[", rightBracket = "]", leftBrace = "{", rightBrace = "}", backslash = "\\", pipe = "|"
    case semicolon = ";", colon = ":", quote = "'", doubleQuote = "\"", comma = ",", period = ".", slash = "/"
    case question = "?", backtick = "`", tilde = "~", greater = ">", lessThan = "<lt>"
    
    // Special keys
    case escape = "<Esc>", enter = "<CR>", backspace = "<BS>", delete = "<Del>", tab = "<Tab>", shiftTab = "<S-Tab>"
    case spaceKey = "<Space>", insert = "<Insert>"

    /**
    ONLY USE ABOVE KEYS FOR NOW.
    */
    
    static var allowedKeys: [VimKeystroke] {
        return [
            // Letters
            .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
            .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
            .A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M,
            .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z,
            
            // Numbers
            .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine,
            
            // Symbols
            .space, .exclamation, .at, .hash, .dollar, .percent, .caret, .ampersand,
            .asterisk, .leftParen, .rightParen, .minus, .underscore, .equals, .plus,
            .leftBracket, .rightBracket, .leftBrace, .rightBrace, .backslash, .pipe,
            .semicolon, .colon, .quote, .doubleQuote, .comma, .period, .slash,
            .question, .backtick, .tilde, .greater, .lessThan,
            
            // Special keys
            .escape, .enter, .backspace, .delete, .tab, .shiftTab,
            .spaceKey, .insert
        ]
    }

    // Arrow keys
    case up = "<Up>", down = "<Down>", left = "<Left>", right = "<Right>"
    
    // Navigation
    case home = "<Home>", end = "<End>", pageUp = "<PageUp>", pageDown = "<PageDown>"
    
    // Function keys
    case f1 = "<F1>", f2 = "<F2>", f3 = "<F3>", f4 = "<F4>", f5 = "<F5>", f6 = "<F6>"
    case f7 = "<F7>", f8 = "<F8>", f9 = "<F9>", f10 = "<F10>", f11 = "<F11>", f12 = "<F12>"
    
    // Ctrl combinations
    case ctrlA = "<C-a>", ctrlB = "<C-b>", ctrlC = "<C-c>", ctrlD = "<C-d>", ctrlE = "<C-e>", ctrlF = "<C-f>", ctrlG = "<C-g>"
    case ctrlH = "<C-h>", ctrlI = "<C-i>", ctrlJ = "<C-j>", ctrlK = "<C-k>", ctrlL = "<C-l>", ctrlM = "<C-m>", ctrlN = "<C-n>"
    case ctrlO = "<C-o>", ctrlP = "<C-p>", ctrlQ = "<C-q>", ctrlR = "<C-r>", ctrlS = "<C-s>", ctrlT = "<C-t>", ctrlU = "<C-u>"
    case ctrlV = "<C-v>", ctrlW = "<C-w>", ctrlX = "<C-x>", ctrlY = "<C-y>", ctrlZ = "<C-z>"
    
    // Meta/Alt combinations
    case metaA = "<M-a>", metaB = "<M-b>", metaC = "<M-c>", metaD = "<M-d>", metaE = "<M-e>", metaF = "<M-f>", metaG = "<M-g>"
    case metaH = "<M-h>", metaI = "<M-i>", metaJ = "<M-j>", metaK = "<M-k>", metaL = "<M-l>", metaM = "<M-m>", metaN = "<M-n>"
    case metaO = "<M-o>", metaP = "<M-p>", metaQ = "<M-q>", metaR = "<M-r>", metaS = "<M-s>", metaT = "<M-t>", metaU = "<M-u>"
    case metaV = "<M-v>", metaW = "<M-w>", metaX = "<M-x>", metaY = "<M-y>", metaZ = "<M-z>"
    
    // Directional modifiers
    case ctrlLeft = "<C-Left>", ctrlRight = "<C-Right>", ctrlUp = "<C-Up>", ctrlDown = "<C-Down>"
    case shiftLeft = "<S-Left>", shiftRight = "<S-Right>", shiftUp = "<S-Up>", shiftDown = "<S-Down>"
    case metaLeft = "<M-Left>", metaRight = "<M-Right>", metaUp = "<M-Up>", metaDown = "<M-Down>"
}