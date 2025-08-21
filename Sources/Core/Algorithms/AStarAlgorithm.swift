/*
Author: <Chuanyu> (skewcy@gmail.com)
AStartSearch.swift (c) 2025
Desc: description
Created:  2025-08-20T19:21:04.471Z
*/

class AStarAlgorithm: AlgorithmProtocol {
    func search(from initialState: VimState, to targetState: VimState, options: SearchOptions) throws -> [VimKeystroke] {
        let startTime = Date()
        let heuristic = options.heuristic.estimate(state: initialState, target: targetState)
        let rootNode = AStarNode(state: initialState, keystrokePath: [], parent: nil, cost: 0, heuristic: heuristic)

        let nodePool = try NodePool([rootNode])
        let vimEngine = try VimEngine(initialState: initialState)
        
        while let currentNode = nodePool.pop() {
            if Date().timeIntervalSince(startTime) > options.timeOut {
                throw SearchError.timeout
            }
            
            if currentNode.state == targetState {
                return currentNode.keystrokePath
            }
            
            let nextKeystrokes = options.neighbors.getNextKeystrokes(state: currentNode.state, target: targetState)
            
            for keystroke in nextKeystrokes {
                let newPath = currentNode.keystrokePath + [keystroke]
                let newState = try vimEngine.execKeystrokes(newPath)
                
                if options.pruning.shouldPrune(state: newState, target: targetState, pool: nodePool) {
                    continue
                }
                
                let gCost = currentNode.cost + 1.0
                let hCost = options.heuristic.estimate(state: newState, target: targetState)
                
                let neighborNode = AStarNode(
                    state: newState,
                    keystrokePath: newPath,
                    parent: currentNode,
                    cost: gCost,
                    heuristic: hCost
                )
                
                nodePool.add(neighborNode)
            }
        }
        
        throw SearchError.noPathFound
    }
}

enum SearchError: Error {
    case timeout
    case noPathFound
}