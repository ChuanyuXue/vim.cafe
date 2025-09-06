/*
Author: <Chuanyu> (skewcy@gmail.com)
AStartSearch.swift (c) 2025
Desc: description
Created:  2025-08-20T19:21:04.471Z
*/

import Foundation

class AStarAlgorithm: AlgorithmProtocol {
    func search(from initialState: VimState, to targetState: VimState, options: SearchOptions) async throws -> [VimKeystroke] {
        let startTime = Date()
        let heuristic = options.heuristic.estimate(state: initialState, target: targetState)
        let rootNode = AStarNode(state: initialState, keystrokePath: [], parent: nil, cost: 0, heuristic: heuristic)

        let nodePool = AStarNodePool()
        await nodePool.add(rootNode)
        let vimEngine = VimEngine(defaultState: initialState)
        
        var iterationCount = 0
        var minPath = [VimKeystroke]()
        
        while let currentNode = await nodePool.pop() {
            iterationCount += 1
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > options.timeOut {
                return minPath
            }
            
            if options.verbose {
                Task {
                    let avgSpeed = elapsed > 0 ? Double(iterationCount) / elapsed : 0
                    await printSearchTable(currentNode: currentNode, nodePool: nodePool, k: 10, avgSpeed: avgSpeed, iterationCount: iterationCount)
                }
            }
            
            if currentNode.state.buffer == targetState.buffer && currentNode.state.mode == targetState.mode {
                minPath = currentNode.keystrokePath
                continue
            }
            
            let nextKeystrokes = options.neighbors.getNextKeystrokes(state: currentNode.state, target: targetState)
            // Snapshot current incumbent bound as Double for pruning-by-bound
            let incumbentBound: Double? = minPath.isEmpty ? nil : Double(minPath.count)
            
            await withTaskGroup(of: AStarNode?.self) { group in
                for keystroke in nextKeystrokes {
                    group.addTask {
                        let newPath = currentNode.keystrokePath + [keystroke]
                        let gCost = (currentNode as! AStarNode).cost + 1.0

                        // 1) Bound pruning (early, before expensive state reconstruction)
                        if options.pruning.shouldPruneByBound(gCost: gCost, incumbentBound: incumbentBound) {
                            return nil
                        }

                        guard let newState = try? await vimEngine.execKeystrokes(newPath) else {
                            return nil
                        }

                        // 2) Domain-specific pruning
                        if options.pruning.shouldPruneByDomain(state: newState, target: targetState) {
                            return nil
                        }

                        let hCost = options.heuristic.estimate(state: newState, target: targetState)
                        
                        return AStarNode(
                            state: newState,
                            keystrokePath: newPath,
                            parent: currentNode,
                            cost: gCost,
                            heuristic: hCost
                        )
                    }
                }
                
                for await neighborNode in group {
                    if let node = neighborNode {
                        await nodePool.add(node)
                    }
                }
            }
        }
        
        return minPath
    }
    
    private func printSearchTable(currentNode: any NodeProtocol, nodePool: AStarNodePool, k: Int, avgSpeed: Double, iterationCount: Int) async {
        let poolNodes = await nodePool.getAllNodes()
        let allNodes = [currentNode] + poolNodes
        let topNodes = Array(allNodes.prefix(k))
        
        // Clear screen and move cursor to top
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        
        print("Iter: \(iterationCount) - \(String(format: "%.2f", avgSpeed)) iter/sec - Pool: \(poolNodes.count)")
        for (index, node) in topNodes.enumerated() {
            if let aStarNode = node as? AStarNode {
                let buffer = formatBuffer(aStarNode.state.buffer)
                let cursor = "[\(aStarNode.state.cursor.col)/\(aStarNode.state.cursor.row)]"
                let mode = aStarNode.state.mode.shortMode
                let depth = aStarNode.keystrokePath.count
                let marker = index == 0 ? "*" : " "
                
                print("\(marker) \(buffer) \(cursor) \(mode) depth:\(depth)")
            }
        }
        print("--------------------------------")
        fflush(stdout)
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
