/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarHeuristic.swift (c) 2025
Desc: description
Created:  2025-08-21T00:44:28.267Z
*/

class AStarHeuristic: HeuristicProtocol {
    func estimate(state: VimState, target: VimState) -> Double {
        let stateBuffer = state.buffer.joined(separator: "\n")
        let targetBuffer = target.buffer.joined(separator: "\n")
        
        let maxLength = max(stateBuffer.count, targetBuffer.count)
        var differences = 0
        
        for i in 0..<maxLength {
            let stateChar = i < stateBuffer.count ? stateBuffer[stateBuffer.index(stateBuffer.startIndex, offsetBy: i)] : nil
            let targetChar = i < targetBuffer.count ? targetBuffer[targetBuffer.index(targetBuffer.startIndex, offsetBy: i)] : nil
            
            if stateChar != targetChar {
                differences += 1
            }
        }
        
        return Double(differences)
    }
}
