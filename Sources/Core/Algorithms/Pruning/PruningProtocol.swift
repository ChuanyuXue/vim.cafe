/*
Author: <Chuanyu> (skewcy@gmail.com)
pruningProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T20:06:24.145Z
*/

protocol PruningProtocol {
    func shouldPrune(state: VimState, target: VimState, pool: NodePoolProtocol) -> Bool
}