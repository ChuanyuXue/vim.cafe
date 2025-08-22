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

@Test func testNodePoolBasicOperations() {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 2), mode: .normal)
    
    let node1 = TestNode(state: state1, priority: 3.0)
    let node2 = TestNode(state: state2, priority: 1.0)
    let node3 = TestNode(state: state3, priority: 2.0)
    
    var pool = AStarNodePool()
    
    #expect(pool.isEmpty())
    #expect(pool.count() == 0)
    
    pool.add(node1)
    pool.add(node2)
    pool.add(node3)
    
    #expect(!pool.isEmpty())
    #expect(pool.count() == 3)
}

@Test func testNodePoolPriorityOrdering() {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 2), mode: .normal)
    
    let node1 = TestNode(state: state1, priority: 3.0)
    let node2 = TestNode(state: state2, priority: 1.0)
    let node3 = TestNode(state: state3, priority: 2.0)
    
    var pool = AStarNodePool()
    pool.add(node1)
    pool.add(node2)
    pool.add(node3)
    
    let first = pool.pop()
    #expect(first?.priority == 1.0)
    
    let second = pool.pop()
    #expect(second?.priority == 2.0)
    
    let third = pool.pop()
    #expect(third?.priority == 3.0)
    
    #expect(pool.isEmpty())
}

@Test func testNodePoolDuplicateHandling() {
    let state = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let node1 = TestNode(state: state, priority: 1.0)
    let node2 = TestNode(state: state, priority: 2.0)
    
    var pool = AStarNodePool()
    pool.add(node1)
    pool.add(node2)
    
    #expect(pool.count() == 1)
    #expect(pool.contains(node1))
    #expect(pool.contains(node2))
}