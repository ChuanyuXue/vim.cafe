/*
Author: <Chuanyu> (skewcy@gmail.com)
AStartNodePool.swift (c) 2025
Desc: Priority queue implementation for A* algorithm nodes
Created:  2025-08-21T01:23:31.704Z
*/

actor AStarNodePool: NodePoolProtocol {
    private var heap: [any NodeProtocol] = []
    private var nodeSet: Set<AnyHashable> = []
    
    init() {}
    
    func initialize(with initialNodes: [any NodeProtocol] = []) {
        for node in initialNodes {
            add(node)
        }
    }
    
    func add(_ node: any NodeProtocol) {
        let nodeHash = AnyHashable(node)
        
        if nodeSet.contains(nodeHash) {
            return
        }
        
        nodeSet.insert(nodeHash)
        heap.append(node)
        heapifyUp(heap.count - 1)
    }

    // Peek at the current minimum-priority node without removing it
    func peek() -> (any NodeProtocol)? {
        return heap.first
    }

    func pop() -> (any NodeProtocol)? {
        guard !heap.isEmpty else { return nil }
        
        if heap.count == 1 {
            let node = heap.removeFirst()
            nodeSet.remove(AnyHashable(node))
            return node
        }
        
        let minNode = heap[0]
        nodeSet.remove(AnyHashable(minNode))
        
        heap[0] = heap.removeLast()
        heapifyDown(0)
        
        return minNode
    }
    
    func remove(_ node: any NodeProtocol) {
        let nodeHash = AnyHashable(node)
        guard nodeSet.contains(nodeHash) else { return }
        
        nodeSet.remove(nodeHash)
        
        if let index = heap.firstIndex(where: { AnyHashable($0) == nodeHash }) {
            if index == heap.count - 1 {
                heap.removeLast()
            } else {
                heap[index] = heap.removeLast()
                heapifyDown(index)
                heapifyUp(index)
            }
        }
    }
    
    func count() -> Int {
        return heap.count
    }
    
    func isEmpty() -> Bool {
        return heap.isEmpty
    }
    
    func contains(_ node: any NodeProtocol) -> Bool {
        return nodeSet.contains(AnyHashable(node))
    }
    
    func getAllNodes() -> [any NodeProtocol] {
        return Array(heap)
    }
    
    private func heapifyUp(_ index: Int) {
        let parentIndex = (index - 1) / 2
        if index > 0 && heap[index].priority < heap[parentIndex].priority {
            heap.swapAt(index, parentIndex)
            heapifyUp(parentIndex)
        }
    }
    
    private func heapifyDown(_ index: Int) {
        let leftChild = 2 * index + 1
        let rightChild = 2 * index + 2
        var smallest = index
        
        if leftChild < heap.count && heap[leftChild].priority < heap[smallest].priority {
            smallest = leftChild
        }
        
        if rightChild < heap.count && heap[rightChild].priority < heap[smallest].priority {
            smallest = rightChild
        }
        
        if smallest != index {
            heap.swapAt(index, smallest)
            heapifyDown(smallest)
        }
    }
}
