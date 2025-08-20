/*
Author: <Chuanyu> (skewcy@gmail.com)
NvimClient.swift (c) 2025
Desc: Low-level interface for nvim RPC communication
Created:  2025-08-19T01:59:11.420Z
*/

import Foundation
import MessagePack

class NvimSession: VimSessionProtocol {
    private var nvimProcess: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var messageId: UInt32 = 0
    
    func start() throws {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nvim")
        process.arguments = ["--headless", "--embed"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
        } catch {
            throw NvimSessionError.startupFailed(error)
        }
        
        self.nvimProcess = process
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe
    }
    
    func stop() {
        inputPipe?.fileHandleForWriting.closeFile()
        outputPipe?.fileHandleForReading.closeFile()
        
        nvimProcess?.terminate()
        
        nvimProcess = nil
        inputPipe = nil
        outputPipe = nil
    }

    func isRunning() -> Bool {
        return nvimProcess != nil && 
               inputPipe != nil && 
               outputPipe != nil && 
               nvimProcess?.isRunning == true
    }
    
    private func callRPC<T>(method: String, params: [Any], parser: ([Any]) throws -> T) throws -> T {
        let msgId = nextMessageId()
        let request = NvimRPC.createRequest(id: msgId, method: method, params: params)
        try sendMessage(request)
        let response = try receiveResponse()
        return try parser(response)
    }
    
    func sendInput(_ input: String) throws {
        try callRPC(method: "nvim_input", params: [input]) { _ in () }
    }
    
    func getBufferLines(buffer: Int, start: Int, end: Int) throws -> [String] {
        try callRPC(method: "nvim_buf_get_lines", params: [buffer, start, end, false]) { response in
            guard response.count >= 4, let result = response[3] as? [String] else {
                throw NvimSessionError.invalidResponse("Failed to get buffer lines")
            }
            return result
        }
    }
    
    func setBufferLines(buffer: Int, start: Int, end: Int, lines: [String]) throws {
        try callRPC(method: "nvim_buf_set_lines", params: [buffer, start, end, false, lines]) { _ in () }
    }
    
    func getCursorPosition(window: Int) throws -> (row: Int, col: Int) {
        try callRPC(method: "nvim_win_get_cursor", params: [window]) { response in
            guard response.count >= 4, let result = response[3] as? [Int], result.count >= 2 else {
                throw NvimSessionError.invalidResponse("Failed to get cursor position")
            }
            return (row: result[0] - 1, col: result[1])
        }
    }
    
    func setCursorPosition(window: Int, row: Int, col: Int) throws {
        try callRPC(method: "nvim_win_set_cursor", params: [window, [row + 1, col]]) { _ in () }
    }
    
    func getMode() throws -> (mode: String, blocking: Bool) {
        try callRPC(method: "nvim_get_mode", params: []) { response in
            guard response.count >= 4, let result = response[3] as? [String: Any],
                  let mode = result["mode"] as? String else {
                throw NvimSessionError.invalidResponse("Failed to get current mode")
            }
            let blocking = result["blocking"] as? Bool ?? false
            return (mode: mode, blocking: blocking)
        }
    }
    
    private func nextMessageId() -> UInt32 {
        messageId += 1
        return messageId
    }
    
    private func sendMessage(_ message: [Any]) throws {
        guard let inputPipe = inputPipe else { throw NvimSessionError.notRunning }
        let data = try NvimRPC.encode(message)
        inputPipe.fileHandleForWriting.write(data)
    }
    
    private func receiveResponse() throws -> [Any] {
        guard let outputPipe = outputPipe else { throw NvimSessionError.notRunning }
        let data = outputPipe.fileHandleForReading.availableData
        guard !data.isEmpty else { throw NvimSessionError.communicationFailed("No data received") }
        return try NvimRPC.decode(data)
    }
}

struct NvimRPC {
    private static let encoder = MessagePackEncoder()
    private static let decoder = MessagePackDecoder()
    
    static func createRequest(id: UInt32, method: String, params: [Any]) -> [Any] {
        return [0, id, method, params]
    }
    
    static func encode(_ object: Any) throws -> Data {
        return try encoder.encode(AnyCodable(object))
    }
    
    static func decode(_ data: Data) throws -> [Any] {
        let decoded = try decoder.decode(AnyCodable.self, from: data)
        return decoded.value as? [Any] ?? [decoded.value]
    }
}

// Wrapper to make Any values Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt32:
            try container.encode(uint)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(value, 
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type: \(type(of: value))"))
        }
    }
}

enum NvimSessionError: Error {
    case startupFailed(Error)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
}

