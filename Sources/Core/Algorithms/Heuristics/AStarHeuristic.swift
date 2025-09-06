/*
Author: <Chuanyu> (skewcy@gmail.com)
AStarHeuristic.swift (c) 2025
Desc: description
Created:  2025-08-21T00:44:28.267Z
*/

class AStarHeuristic: HeuristicProtocol {
    enum Mode {
        case normalizedLevenshtein
        case positionalDifference
    }

    private let mode: Mode

    init(mode: Mode = .positionalDifference) {
        self.mode = mode
    }

    func estimate(state: VimState, target: VimState) -> Double {
        let a = state.buffer.joined(separator: "\n")
        let b = target.buffer.joined(separator: "\n")

        switch mode {
        case .normalizedLevenshtein:
            return Self.normalizedLevenshtein(a: a, b: b)
        case .positionalDifference:
            return Self.positionalDifference(a: a, b: b)
        }
    }

    private static func normalizedLevenshtein(a: String, b: String) -> Double {
        // Fast paths
        if a == b { return 0.0 }
        let aCount = a.count
        let bCount = b.count
        if aCount == 0 { return 1.0 } // b != "" so fully different
        if bCount == 0 { return 1.0 }

        // Compute normalized Levenshtein edit distance in [0, 1]
        let dist = levenshteinDistance(a, b)
        let norm = Double(dist) / Double(max(aCount, bCount))
        return norm
    }

    private static func positionalDifference(a: String, b: String) -> Double {
        let maxLength = max(a.count, b.count)
        var differences = 0

        for i in 0..<maxLength {
            let aChar = i < a.count ? a[a.index(a.startIndex, offsetBy: i)] : nil
            let bChar = i < b.count ? b[b.index(b.startIndex, offsetBy: i)] : nil
            if aChar != bChar { differences += 1 }
        }
        return Double(differences)
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        // Convert to arrays of Characters for stable indexing
        let s = Array(lhs)
        let t = Array(rhs)

        if s.isEmpty { return t.count }
        if t.isEmpty { return s.count }

        // Ensure t is the longer dimension to minimize memory
        if s.count > t.count {
            return levenshteinDistance(rhs, lhs)
        }

        let n = s.count
        let m = t.count

        var previous = Array(0...m) // [0, 1, 2, ..., m]
        var current = Array(repeating: 0, count: m + 1)

        for i in 1...n {
            current[0] = i
            let sChar = s[i - 1]
            for j in 1...m {
                let cost = (sChar == t[j - 1]) ? 0 : 1
                let deletion = previous[j] + 1
                let insertion = current[j - 1] + 1
                let substitution = previous[j - 1] + cost
                current[j] = min(deletion, insertion, substitution)
            }
            swap(&previous, &current)
        }

        return previous[m]
    }
}
