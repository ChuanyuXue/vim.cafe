/*
Author: <Chuanyu> (skewcy@gmail.com)
NodePoolProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T20:01:15.939Z
*/

protocol NodePoolProtocol {
    mutating func add(_ node: NodeProtocol)
    mutating func pop() -> NodeProtocol?
    mutating func remove(_ node: NodeProtocol)

    func count() -> Int
    func isEmpty() -> Bool
    func contains(_ node: NodeProtocol) -> Bool
}