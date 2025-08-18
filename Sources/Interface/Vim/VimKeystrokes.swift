/*
Author: <Chuanyu> (skewcy@gmail.com)
VimKeystrokes.swift (c) 2025
Desc: Simple keystroke definitions for nvim RPC
Created:  2025-08-17T20:15:34.781Z
*/

import Foundation

let KEYSTROKES: [String] = [
    // Letters
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    
    // Numbers
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    
    // Symbols (all printable ASCII 32-126, except < which is <LT>)
    " ", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_",
    "=", "+", "[", "]", "{", "}", "\\", "|", ";", ":", "'", "\"",
    ",", ".", "/", "?", "`", "~", ">", "<LT>",  // <LT> for literal <
    
    // Basic special keys
    "<Esc>", "<CR>", "<BS>", "<Del>", "<Tab>", "<S-Tab>", "<Space>",
    "<Insert>",
    
    // Arrow keys
    "<Up>", "<Down>", "<Left>", "<Right>",
    
    // Navigation keys
    "<Home>", "<End>", "<PageUp>", "<PageDown>",
    
    // Function keys F1-F12
    "<F1>", "<F2>", "<F3>", "<F4>", "<F5>", "<F6>",
    "<F7>", "<F8>", "<F9>", "<F10>", "<F11>", "<F12>",
    
    // Ctrl combinations (all letters)
    "<C-a>", "<C-b>", "<C-c>", "<C-d>", "<C-e>", "<C-f>", "<C-g>",
    "<C-h>", "<C-i>", "<C-j>", "<C-k>", "<C-l>", "<C-m>", "<C-n>",
    "<C-o>", "<C-p>", "<C-q>", "<C-r>", "<C-s>", "<C-t>", "<C-u>",
    "<C-v>", "<C-w>", "<C-x>", "<C-y>", "<C-z>",
    
    // Meta/Alt combinations (all letters)
    "<M-a>", "<M-b>", "<M-c>", "<M-d>", "<M-e>", "<M-f>", "<M-g>",
    "<M-h>", "<M-i>", "<M-j>", "<M-k>", "<M-l>", "<M-m>", "<M-n>",
    "<M-o>", "<M-p>", "<M-q>", "<M-r>", "<M-s>", "<M-t>", "<M-u>",
    "<M-v>", "<M-w>", "<M-x>", "<M-y>", "<M-z>",
    
    // Directional modifier combinations
    "<C-Left>", "<C-Right>", "<C-Up>", "<C-Down>",
    "<S-Left>", "<S-Right>", "<S-Up>", "<S-Down>",
    "<M-Left>", "<M-Right>", "<M-Up>", "<M-Down>"
]