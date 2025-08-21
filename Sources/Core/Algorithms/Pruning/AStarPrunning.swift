/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarPrunning.swift (c) 2025
Desc: description
Created:  2025-08-21T01:22:47.967Z
*/

class AStarPrunning: PruningProtocol {
    func shouldPrune(state: VimState, target: VimState, pool: NodePoolProtocol) -> Bool {
        return false
    }
}