/*
Author: <Chuanyu> (skewcy@gmail.com)
NeighborsProtocol.swift (c) 2025
Desc: description
Created:  2025-08-21T01:20:57.571Z
*/

protocol NeighborsProtocol {
    func getNextKeystrokes(state: VimState, target: VimState) -> [VimKeystroke]
}