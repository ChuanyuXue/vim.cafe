/*
Author: <Chuanyu> (skewcy@gmail.com)
AlgorithmProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T19:15:06.347Z
*/

import Foundation

protocol AlgorithmProtocol {
    func search(from initialState: VimState, to targetState: VimState, options: SearchOptions) throws -> [VimKeystroke]
}

struct SearchOptions {
    let timeOut: TimeInterval

    let neighbors: NeighborsProtocol
    let pruning: PruningProtocol
    let heuristic: HeuristicProtocol
}