/*
Author: <Chuanyu> (skewcy@gmail.com)
AStartNeighbors.swift (c) 2025
Desc: description
Created:  2025-08-21T01:22:01.688Z
*/

class AStarNeighbors: NeighborsProtocol {
    func getNextKeystrokes(state: VimState, target: VimState) -> [VimKeystroke] {
        return VimKeystroke.allowedKeys
    }
}