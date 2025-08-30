/*
Author: <Chuanyu> (skewcy@gmail.com)
VimStateLRU.swift (c) 2025
Desc: LRU cache for storing VimState by keystroke sequences
Created:  2025-08-30T00:00:00.000Z

Should not use LRU but use a prefix tree and save state at leaf nodes. 
Because we need to make sure the longest available state must be cached.
*/

import Foundation

actor VimStateLRU {
    private final class Node {
        let key: [VimKeystroke]
        var value: VimState
        var prev: Node?
        var next: Node?
        
        init(key: [VimKeystroke], value: VimState) {
            self.key = key
            self.value = value
        }
    }
    
    private let capacity: Int
    private var cache: [String: Node] = [:]
    private let head = Node(key: [], value: VimState(buffer: [], cursor: VimCursor(row: 0, col: 0), mode: .normal))
    private let tail = Node(key: [], value: VimState(buffer: [], cursor: VimCursor(row: 0, col: 0), mode: .normal))
    
    init(capacity: Int = 1000) {
        self.capacity = capacity
        head.next = tail
        tail.prev = head
    }
    
    func get(_ keystrokes: [VimKeystroke]) -> VimState? {
        let key = encodeKeystrokes(keystrokes)
        
        guard let node = cache[key] else {
            return nil
        }
        
        moveToHead(node)
        return node.value
    }
    
    func set(_ keystrokes: [VimKeystroke], _ value: VimState) {
        let key = encodeKeystrokes(keystrokes)
        
        if let node = cache[key] {
            node.value = value
            moveToHead(node)
        } else {
            let newNode = Node(key: keystrokes, value: value)
            cache[key] = newNode
            addToHead(newNode)
            
            if cache.count > capacity {
                if let tailNode = removeTail() {
                    cache.removeValue(forKey: encodeKeystrokes(tailNode.key))
                }
            }
        }
    }
    
    func remove(_ keystrokes: [VimKeystroke]) {
        let key = encodeKeystrokes(keystrokes)
        
        if let node = cache[key] {
            cache.removeValue(forKey: key)
            removeNode(node)
        }
    }
    
    func clear() {
        cache.removeAll()
        head.next = tail
        tail.prev = head
    }
    
    func count() -> Int {
        return cache.count
    }
    
    private func addToHead(_ node: Node) {
        node.prev = head
        node.next = head.next
        head.next?.prev = node
        head.next = node
    }
    
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
    
    private func moveToHead(_ node: Node) {
        removeNode(node)
        addToHead(node)
    }
    
    private func removeTail() -> Node? {
        guard let lastNode = tail.prev, lastNode !== head else {
            return nil
        }
        removeNode(lastNode)
        return lastNode
    }
}