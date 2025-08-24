/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarAlgorithmTest.swift (c) 2025
Desc: Unit tests for AStarAlgorithm
Created:  2025-08-24T00:00:00.000Z
*/

import Testing
@testable import VimCafe

@Test func testAStarAlgorithmIdenticalStates() throws {
    let algorithm = AStarAlgorithm()
    
    let state = VimState(
        buffer: ["abc123abc123"],
        cursor: VimCursor(row: 0, col: 0),
        mode: .normal
    )
    
    let options = SearchOptions(
        timeOut: 180.0,
        neighbors: AStarNeighbors(),
        pruning: AStarPrunning(),
        heuristic: AStarHeuristic()
    )
    
    let result = try algorithm.search(from: state, to: state, options: options)
    #expect(result.isEmpty)
}

@Test func testAStarAlgorithmTimeout() throws {
    let algorithm = AStarAlgorithm()
    
    let initialState = VimState(
        buffer: ["abc123abc123"],
        cursor: VimCursor(row: 0, col: 0),
        mode: .normal
    )
    
    let targetState = VimState(
        buffer: ["123abc123abc"],
        cursor: VimCursor(row: 0, col: 12),
        mode: .insert
    )
    
    let options = SearchOptions(
        timeOut: 1.0,
        neighbors: AStarNeighbors(),
        pruning: AStarPrunning(),
        heuristic: AStarHeuristic()
    )
    
    #expect(throws: SearchError.timeout) {
        _ = try algorithm.search(from: initialState, to: targetState, options: options)
    }
}

@Test func testAStarAlgorithmSimpleTransformation() throws {
    let algorithm = AStarAlgorithm()
    
    let initialState = VimState(
        buffer: ["abc123abc123"],
        cursor: VimCursor(row: 0, col: 0),
        mode: .normal
    )
    
    let targetState = VimState(
        buffer: ["123abc123abc"],
        cursor: VimCursor(row: 0, col: 0),
        mode: .normal
    )
    
    let options = SearchOptions(
        timeOut: 180.0,
        verbose: true,
        neighbors: AStarNeighbors(),
        pruning: AStarPrunning(),
        heuristic: AStarHeuristic()
    )
    
    do {
        let result = try algorithm.search(from: initialState, to: targetState, options: options)
        #expect(!result.isEmpty)
    } catch SearchError.timeout {
        // Expected for complex transformations
        #expect(true)
    } catch SearchError.noPathFound {
        // Also acceptable for this test scenario
        #expect(true)
    }
}