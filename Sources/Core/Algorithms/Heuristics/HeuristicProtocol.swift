/*
Author: <Chuanyu> (skewcy@gmail.com)
HeuristicProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T19:22:35.041Z
*/

protocol HeuristicProtocol {
    func getNextKeystrokes(node: NodeProtocol, pool: NodePoolProtocol) -> [VimKeystroke]
}