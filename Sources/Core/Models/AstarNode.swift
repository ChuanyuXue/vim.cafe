/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarNode.swift (c) 2025
Desc: description
Created:  2025-08-20T19:31:48.305Z
*/

struct AStarNode: NodeProtocol {
    let state: VimState
    let keystrokePath: [VimKeystroke]
    let parent: NodeProtocol?

    private let cost: Double
    private let heuristic: Double

    var priority: Double {
        return cost + heuristic
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
    }

    static func == (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.state == rhs.state
    }
}
