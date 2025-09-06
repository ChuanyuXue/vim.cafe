/*
Author: <Chuanyu> (skewcy@gmail.com)
pruningProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T20:06:24.145Z
*/

protocol PruningProtocol {
    // Cost-bound pruning (branch-and-bound). Safe when gCost >= incumbentBound.
    func shouldPruneByBound(gCost: Double, incumbentBound: Double?) -> Bool

    // Domain-specific pruning (e.g., no-ops, symmetry, immediate backtracks).
    func shouldPruneByDomain(state: VimState, target: VimState) -> Bool
}
