/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarNodeTest.swift (c) 2025
Desc: Unit tests for AStarNode
Created:  2025-08-21T01:23:31.704Z
*/

import Testing
@testable import VimCafe

@Test func testAStarNodeInitialization() {
    let state = VimState(buffer: ["hello world"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let keystrokes: [VimKeystroke] = [.w, .e]
    let cost = 2.5
    let heuristic = 3.2
    
    let node = AStarNode(
        state: state,
        keystrokePath: keystrokes,
        parent: nil,
        cost: cost,
        heuristic: heuristic
    )
    
    #expect(node.state == state)
    #expect(node.keystrokePath == keystrokes)
    #expect(node.parent == nil)
    #expect(node.cost == cost)
    #expect(node.heuristic == heuristic)
}

@Test func testAStarNodePriorityCalculation() {
    let state = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let cost = 2.0
    let heuristic = 3.5
    
    let node = AStarNode(
        state: state,
        keystrokePath: [],
        parent: nil,
        cost: cost,
        heuristic: heuristic
    )
    
    #expect(node.priority == cost + heuristic)
    #expect(node.priority == 5.5)
}

@Test func testAStarNodeWithParent() {
    let parentState = VimState(buffer: ["parent"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let parentNode = AStarNode(
        state: parentState,
        keystrokePath: [.w],
        parent: nil,
        cost: 1.0,
        heuristic: 2.0
    )
    
    let childState = VimState(buffer: ["child"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    let childNode = AStarNode(
        state: childState,
        keystrokePath: [.w, .e],
        parent: parentNode,
        cost: 2.0,
        heuristic: 1.5
    )
    
    #expect(childNode.parent != nil)
    #expect(childNode.keystrokePath.count == 2)
    #expect(childNode.keystrokePath == [.w, .e])
}

@Test func testAStarNodeEquality() {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    
    let node1 = AStarNode(
        state: state1,
        keystrokePath: [.w],
        parent: nil,
        cost: 1.0,
        heuristic: 2.0
    )
    
    let node2 = AStarNode(
        state: state2,
        keystrokePath: [.e],
        parent: nil,
        cost: 3.0,
        heuristic: 1.0
    )
    
    let node3 = AStarNode(
        state: state3,
        keystrokePath: [.w],
        parent: nil,
        cost: 1.0,
        heuristic: 2.0
    )
    
    // Nodes with same state should be equal regardless of other properties
    #expect(node1 == node2)
    // Nodes with different states should not be equal
    #expect(node1 != node3)
}

@Test func testAStarNodeHashing() {
    let state1 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state2 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let state3 = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 1), mode: .normal)
    
    let node1 = AStarNode(
        state: state1,
        keystrokePath: [.w],
        parent: nil,
        cost: 1.0,
        heuristic: 2.0
    )
    
    let node2 = AStarNode(
        state: state2,
        keystrokePath: [.e],
        parent: nil,
        cost: 3.0,
        heuristic: 1.0
    )
    
    let node3 = AStarNode(
        state: state3,
        keystrokePath: [.w],
        parent: nil,
        cost: 1.0,
        heuristic: 2.0
    )
    
    // Nodes with same state should have same hash
    #expect(node1.hashValue == node2.hashValue)
    // Nodes with different states should likely have different hashes
    #expect(node1.hashValue != node3.hashValue)
}

@Test func testAStarNodeZeroCostAndHeuristic() {
    let state = VimState(buffer: [""], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    
    let node = AStarNode(
        state: state,
        keystrokePath: [],
        parent: nil,
        cost: 0.0,
        heuristic: 0.0
    )
    
    #expect(node.cost == 0.0)
    #expect(node.heuristic == 0.0)
    #expect(node.priority == 0.0)
}

@Test func testAStarNodeWithComplexKeystrokePath() {
    let state = VimState(buffer: ["hello world"], cursor: VimCursor(row: 0, col: 5), mode: .insert)
    let keystrokes: [VimKeystroke] = [.w, .w, .e, .a, .space, .h, .e, .l, .l, .o]
    
    let node = AStarNode(
        state: state,
        keystrokePath: keystrokes,
        parent: nil,
        cost: 10.0,
        heuristic: 5.0
    )
    
    #expect(node.keystrokePath.count == 10)
    #expect(node.keystrokePath == keystrokes)
    #expect(node.state.mode == .insert)
    #expect(node.state.cursor.col == 5)
}

@Test func testAStarNodeDifferentModes() {
    let normalState = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
    let insertState = VimState(buffer: ["test"], cursor: VimCursor(row: 0, col: 0), mode: .insert)
    
    let normalNode = AStarNode(
        state: normalState,
        keystrokePath: [],
        parent: nil,
        cost: 1.0,
        heuristic: 1.0
    )
    
    let insertNode = AStarNode(
        state: insertState,
        keystrokePath: [],
        parent: nil,
        cost: 1.0,
        heuristic: 1.0
    )
    
    // Different modes should result in different nodes
    #expect(normalNode != insertNode)
    #expect(normalNode.state.mode == .normal)
    #expect(insertNode.state.mode == .insert)
}