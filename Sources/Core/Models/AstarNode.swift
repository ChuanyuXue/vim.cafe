/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarNode.swift (c) 2025
Desc: description
Created:  2025-08-20T19:31:48.305Z
*/

struct AStarNode: NodeProtocol {
    let state: VimState
    let keystrokePath: [VimKeystroke]
    let parent: (any NodeProtocol)?

    let cost: Double
    let heuristic: Double

    init(state: VimState, keystrokePath: [VimKeystroke], parent: (any NodeProtocol)?, cost: Double, heuristic: Double) {
        self.state = state
        self.keystrokePath = keystrokePath
        self.parent = parent
        self.cost = cost
        self.heuristic = heuristic
    }

    var priority: Double {
        return cost + heuristic
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
    }

    // TODO: This needs to be reconsidered.
    // Because hidden states are not considered.
    static func == (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.state == rhs.state
    }
}
