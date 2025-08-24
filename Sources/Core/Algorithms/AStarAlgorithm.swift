/*
Author: <Chuanyu> (skewcy@gmail.com)
AStartSearch.swift (c) 2025
Desc: description
Created:  2025-08-20T19:21:04.471Z
*/

import Foundation

class AStarAlgorithm: AlgorithmProtocol {
    func search(from initialState: VimState, to targetState: VimState, options: SearchOptions) throws -> [VimKeystroke] {
        let startTime = Date()
        let heuristic = options.heuristic.estimate(state: initialState, target: targetState)
        let rootNode = AStarNode(state: initialState, keystrokePath: [], parent: nil, cost: 0, heuristic: heuristic)

        var nodePool = AStarNodePool()
        nodePool.add(rootNode)
        let vimEngine = VimEngine(defaultState: initialState)
        
        while let currentNode = nodePool.pop() {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > options.timeOut {
                throw SearchError.timeout
            }
            
            if options.verbose {
                printSearchTable(currentNode: currentNode, nodePool: nodePool)
            }
            
            if currentNode.state == targetState {
                return currentNode.keystrokePath
            }
            
            let nextKeystrokes = options.neighbors.getNextKeystrokes(state: currentNode.state, target: targetState)
            
            for keystroke in nextKeystrokes {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > options.timeOut {
                    throw SearchError.timeout
                }
                
                let newPath = currentNode.keystrokePath + [keystroke]
                let newState = try vimEngine.execKeystrokes(newPath)

                print("newPath: \(encodeKeystrokes(newPath))")
                
                if options.pruning.shouldPrune(state: newState, target: targetState, pool: nodePool) {
                    continue
                }
                
                let gCost = (currentNode as! AStarNode).cost + 1.0
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
    
    private func printSearchTable(currentNode: any NodeProtocol, nodePool: AStarNodePool) {
        let allNodes = [currentNode] + nodePool.getAllNodes()
        
        for (index, node) in allNodes.enumerated() {
            if let aStarNode = node as? AStarNode {
                let buffer = formatBuffer(aStarNode.state.buffer)
                let cursor = "[\(aStarNode.state.cursor.col)/\(aStarNode.state.cursor.row)]"
                let mode = aStarNode.state.mode.shortMode
                let marker = index == 0 ? "*" : " "
                
                print("\(marker) \(buffer) \(cursor) \(mode)")
            }
        }
        print()
    }
    
    private func formatBuffer(_ buffer: [String]) -> String {
        let joined = buffer.joined(separator: " ")
        let fixedWidth = 20
        
        if joined.count > fixedWidth {
            return String(joined.prefix(fixedWidth))
        } else {
            return joined.padding(toLength: fixedWidth, withPad: " ", startingAt: 0)
        }
    }
}

enum SearchError: Error {
    case timeout
    case noPathFound
}