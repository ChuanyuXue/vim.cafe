/*
Author: <Chuanyu> (skewcy@gmail.com)
NodePoolProtocol.swift (c) 2025
Desc: description
Created:  2025-08-20T20:01:15.939Z
*/

protocol NodePoolProtocol {
    func add(_ node: any NodeProtocol) async
    func pop() async -> (any NodeProtocol)?
    func remove(_ node: any NodeProtocol) async

    func count() async -> Int
    func isEmpty() async -> Bool
    func contains(_ node: any NodeProtocol) async -> Bool
}