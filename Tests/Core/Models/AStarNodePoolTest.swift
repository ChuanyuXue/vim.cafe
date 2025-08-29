/*
Author: <Chuanyu> (skewcy@gmail.com)
NodePoolTest.swift (c) 2025
Desc: Test for NodePool priority queue implementation
Created:  2025-08-21T01:23:31.704Z
*/

import Testing
@testable import VimCafe

struct TestNode: NodeProtocol {
    let state: VimState
    let keystrokePath: [VimKeystroke]
    let parent: (any NodeProtocol)?
    let priority: Double
    
    init(state: VimState, keystrokePath: [VimKeystroke] = [], parent: (any NodeProtocol)? = nil, priority: Double) {
        self.state = state
        self.keystrokePath = keystrokePath
        self.parent = parent
        self.priority = priority
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
    }
    
    static func == (lhs: TestNode, rhs: TestNode) -> Bool {
        return lhs.state == rhs.state
    }
}

@Test func testNodePoolBasicOperations() async {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 2), mode: .normal)
    
    let node1 = TestNode(state: state1, priority: 3.0)
    let node2 = TestNode(state: state2, priority: 1.0)
    let node3 = TestNode(state: state3, priority: 2.0)
    
    let pool = AStarNodePool()
    
    #expect(await pool.isEmpty())
    #expect(await pool.count() == 0)
    
    await pool.add(node1)
    await pool.add(node2)
    await pool.add(node3)
    
    #expect(!(await pool.isEmpty()))
    #expect(await pool.count() == 3)
}

@Test func testNodePoolPriorityOrdering() async {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 2), mode: .normal)
    
    let node1 = TestNode(state: state1, priority: 3.0)
    let node2 = TestNode(state: state2, priority: 1.0)
    let node3 = TestNode(state: state3, priority: 2.0)
    
    let pool = AStarNodePool()
    await pool.add(node1)
    await pool.add(node2)
    await pool.add(node3)
    
    let first = await pool.pop()
    #expect(first?.priority == 1.0)
    
    let second = await pool.pop()
    #expect(second?.priority == 2.0)
    
    let third = await pool.pop()
    #expect(third?.priority == 3.0)
    
    #expect(await pool.isEmpty())
}

@Test func testNodePoolDuplicateHandling() async {
    let state = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let node1 = TestNode(state: state, priority: 1.0)
    let node2 = TestNode(state: state, priority: 2.0)
    
    let pool = AStarNodePool()
    await pool.add(node1)
    await pool.add(node2)
    
    #expect(await pool.count() == 1)
    #expect(await pool.contains(node1))
    #expect(await pool.contains(node2))
}