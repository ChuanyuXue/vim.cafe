/*
Author: <Chuanyu> (skewcy@gmail.com)
SearchNode.swift (c) 2025
Desc: description
Created:  2025-08-17T20:15:56.791Z
*/

protocol NodeProtocol: Hashable {
    var state: VimState { get }
    var keystrokePath: [VimKeystroke] { get }
    var priority: Double { get }
    var parent: NodeProtocol? { get }
}

