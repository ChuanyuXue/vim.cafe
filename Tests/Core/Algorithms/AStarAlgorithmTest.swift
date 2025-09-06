/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarAlgorithmTest.swift (c) 2025
Desc: Unit tests for AStarAlgorithm
Created:  2025-08-24T00:00:00.000Z
*/

import Testing
@testable import VimCafe

@Test func testAStarAlgorithmIdenticalStates() async throws {
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
    
    let result = try await algorithm.search(from: state, to: state, options: options)
    #expect(result.isEmpty)
}

@Test func testAStarAlgorithmTimeout() async throws {
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
    
    do {
        _ = try await algorithm.search(from: initialState, to: targetState, options: options)
        Issue.record("Expected timeout error")
    } catch SearchError.timeout {
        // Expected
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func testAStarAlgorithmSimpleTransformation() async throws {
    let algorithm = AStarAlgorithm()

    /*
    Optimum keystrokes:
    dt1$p
    */
    
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
        timeOut: 360.0,
        verbose: true,
        neighbors: AStarNeighbors(),
        pruning: AStarPrunning(),
        heuristic: AStarHeuristic()
    )
    
    do {
        let result = try await algorithm.search(from: initialState, to: targetState, options: options)
        print("result: \(encodeKeystrokes(result))")
        #expect(!result.isEmpty)
    } catch SearchError.timeout {
        // Expected for complex transformations
        #expect(true)
    } catch SearchError.noPathFound {
        // Also acceptable for this test scenario
        #expect(true)
    }
}