/*
Author: <Chuanyu> (skewcy@gmail.com)
AstarNode.swift (c) 2025
Desc: description
Created:  2025-08-20T19:31:48.305Z
*/

struct AstarNode: NodeProtocol {
    let state: VimState
    let keystrokePath: [VimKeystroke]

    private let g: Double
    private let h: Double

    var weight: Double {
        return g + h
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keystrokePath)
    }

    static func == (lhs: AstarNode, rhs: AstarNode) -> Bool {
        return lhs.keystrokePath == rhs.keystrokePath
    }
}
