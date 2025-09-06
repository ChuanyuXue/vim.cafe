/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarPrunning.swift (c) 2025
Desc: description
Created:  2025-08-21T01:22:47.967Z
*/

class AStarPrunning: PruningProtocol {
    func shouldPruneByBound(gCost: Double, incumbentBound: Double?) -> Bool {
        // Safe cost-bound pruning using ONLY g (path cost so far).
        if let bound = incumbentBound, gCost >= bound {
            return true
        }
        return false
    }

    func shouldPruneByDomain(state: VimState, target: VimState) -> Bool {
        // No domain-specific pruning by default.
        // Examples (not implemented):
        // - Avoid immediate inverse moves (e.g., h right after l, j after k)
        // - Skip no-op transitions
        return false
    }
}
