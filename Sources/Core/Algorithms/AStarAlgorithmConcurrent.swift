/*
Author: <Chuanyu> (skewcy@gmail.com)
ConcurrentAStarAlgorithm.swift (c) 2025
Desc: A* with single dispatcher and concurrent expanders (producer/consumer)
Created:  2025-09-06
*/

import Foundation

final class AStarAlgorithmConcurrent: AlgorithmProtocol {
    private let maxConcurrentExpansions: Int

    init(maxConcurrentExpansions: Int = 4) {
        self.maxConcurrentExpansions = max(1, maxConcurrentExpansions)
    }

    func search(from initialState: VimState, to targetState: VimState, options: SearchOptions) async throws -> [VimKeystroke] {
        let startTime = Date()

        // Root
        let rootHeuristic = options.heuristic.estimate(state: initialState, target: targetState)
        let rootNode = AStarNode(state: initialState, keystrokePath: [], parent: nil, cost: 0, heuristic: rootHeuristic)

        // Open set managed by dispatcher
        let open = AStarNodePool()
        await open.add(rootNode)

        // Shared Vim engine
        let vimEngine = VimEngine(defaultState: initialState)

        // Shared trackers (actors for safe concurrency)
        let trackers = SearchTrackers()

        var iterationCount = 0

        while true {
            // Timeout
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > options.timeOut {
                throw SearchError.timeout
            }

            // Verbose snapshot
            if options.verbose {
                Task { [iterationCount] in
                    let avgSpeed = elapsed > 0 ? Double(max(1, iterationCount)) / elapsed : 0
                    await self.printSearchTable(nodePool: open, k: 10, avgSpeed: avgSpeed, iterationCount: iterationCount)
                }
            }

            // If a goal is known, check safe termination condition
            if let incumbentBound = await trackers.bestBound() {
                let openMinF = await open.peek()?.priority
                let inflight = await trackers.inFlight()
                if inflight == 0, let minF = openMinF, incumbentBound <= minF {
                    return await trackers.bestPath() ?? []
                }
            }

            // Backoff if expansions saturated
            while await trackers.inFlight() >= maxConcurrentExpansions {
                try await Task.sleep(nanoseconds: 200_000) // 0.2ms
            }

            // Pop next node; if none and nothing in-flight, conclude
            guard let currentAny = await open.pop() else {
                if await trackers.inFlight() == 0 { break }
                try await Task.sleep(nanoseconds: 200_000)
                continue
            }

            iterationCount += 1

            guard let current = currentAny as? AStarNode else { continue }

            // If current is goal, record candidate best and continue (don’t terminate early)
            if current.state.buffer == targetState.buffer && current.state.mode == targetState.mode {
                await trackers.consider(path: current.keystrokePath)
            }

            // Dispatch expansion as a concurrent task
            await trackers.inc()
            Task.detached { [options] in
                defer { Task { await trackers.dec() } }

                let nextKeystrokes = options.neighbors.getNextKeystrokes(state: current.state, target: targetState)

                for key in nextKeystrokes {
                    // Check bound pruning using current incumbent
                    let newPath = current.keystrokePath + [key]
                    let gCost = current.cost + 1.0
                    if await options.pruning.shouldPruneByBound(gCost: gCost, incumbentBound: await trackers.bestBound()) {
                        continue
                    }

                    let s = try! await vimEngine.execKeystrokes(newPath)

                    // Domain-specific pruning
                    if options.pruning.shouldPruneByDomain(state: s, target: targetState) {
                        continue
                    }

                    let h = options.heuristic.estimate(state: s, target: targetState)
                    let succ = AStarNode(state: s, keystrokePath: newPath, parent: current, cost: gCost, heuristic: h)

                    // If successor hits goal, update incumbent
                    if s.buffer == targetState.buffer && s.mode == targetState.mode {
                        await trackers.consider(path: newPath)
                    }

                    await open.add(succ)
                }
            }
        }

        // Fallback: return best found or no path
        if let best = await trackers.bestPath() { return best }
        throw SearchError.noPathFound
    }

    // MARK: - Verbose helpers
    private func printSearchTable(nodePool: AStarNodePool, k: Int, avgSpeed: Double, iterationCount: Int) async {
        let poolNodes = await nodePool.getAllNodes()
        let topNodes = Array(poolNodes.prefix(k))

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

// MARK: - Private helpers
private actor SearchTrackers {
    private var inFlightCount: Int = 0
    private var bestPathSoFar: [VimKeystroke]? = nil

    func inc() { inFlightCount += 1 }
    func dec() { inFlightCount = max(0, inFlightCount - 1) }
    func inFlight() -> Int { inFlightCount }

    func consider(path: [VimKeystroke]) {
        if let best = bestPathSoFar {
            if path.count < best.count { bestPathSoFar = path }
        } else {
            bestPathSoFar = path
        }
    }

    func bestBound() -> Double? {
        guard let best = bestPathSoFar else { return nil }
        return Double(best.count)
    }

    func bestPath() -> [VimKeystroke]? { bestPathSoFar }
}
