/*
Author: <Chuanyu> (skewcy@gmail.com)
NvimClient.swift (c) 2025
Desc: Low-level interface for nvim RPC communication
Created:  2025-08-19T01:59:11.420Z
*/

import Foundation

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
            throw NvimClientError.startupFailed(error)
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
                throw NvimClientError.invalidResponse("Failed to get buffer lines")
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
                throw NvimClientError.invalidResponse("Failed to get cursor position")
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
                throw NvimClientError.invalidResponse("Failed to get current mode")
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
        guard let inputPipe = inputPipe else { throw NvimClientError.notRunning }
        let data = try NvimRPC.encode(message)
        inputPipe.fileHandleForWriting.write(data)
    }
    
    private func receiveResponse() throws -> [Any] {
        guard let outputPipe = outputPipe else { throw NvimClientError.notRunning }
        let data = outputPipe.fileHandleForReading.availableData
        guard !data.isEmpty else { throw NvimClientError.communicationFailed("No data received") }
        return try NvimRPC.decode(data)
    }
}

struct NvimRPC {
    static func createRequest(id: UInt32, method: String, params: [Any]) -> [Any] {
        return [0, id, method, params]
    }
    
    static func encode(_ object: Any) throws -> Data {
        var data = Data()
        try encodeValue(object, to: &data)
        return data
    }
    
    static func decode(_ data: Data) throws -> [Any] {
        var offset = 0
        let value = try decodeValue(from: data, offset: &offset)
        if let array = value as? [Any] {
            return array
        } else {
            return [value]
        }
    }
    
    private static func encodeValue(_ value: Any, to data: inout Data) throws {
        switch value {
        case let array as [Any]: try encodeArray(array, to: &data)
        case let string as String: try encodeString(string, to: &data)
        case let number as UInt32: try encodeUInt32(number, to: &data)
        case let number as Int: try encodeInt(number, to: &data)
        case let bool as Bool: data.append(bool ? 0xC3 : 0xC2)
        default: throw NvimClientError.communicationFailed("Unsupported type")
        }
    }
    
    private static func encodeArray(_ array: [Any], to data: inout Data) throws {
        let count = array.count
        if count <= 15 {
            data.append(UInt8(0x90 + count))
        } else if count <= 0xFFFF {
            data.append(0xDC)
            data.append(UInt8(count >> 8))
            data.append(UInt8(count & 0xFF))
        } else {
            throw NvimClientError.communicationFailed("Array too large")
        }
        for item in array { try encodeValue(item, to: &data) }
    }
    
    private static func encodeString(_ string: String, to data: inout Data) throws {
        let bytes = Array(string.utf8)
        let count = bytes.count
        if count <= 31 {
            data.append(UInt8(0xA0 + count))
        } else if count <= 0xFF {
            data.append(0xD9)
            data.append(UInt8(count))
        } else if count <= 0xFFFF {
            data.append(0xDA)
            data.append(UInt8(count >> 8))
            data.append(UInt8(count & 0xFF))
        } else {
            throw NvimClientError.communicationFailed("String too large")
        }
        data.append(contentsOf: bytes)
    }
    
    private static func encodeUInt32(_ value: UInt32, to data: inout Data) throws {
        if value <= 127 {
            data.append(UInt8(value))
        } else if value <= 0xFF {
            data.append(0xCC)
            data.append(UInt8(value))
        } else if value <= 0xFFFF {
            data.append(0xCD)
            data.append(UInt8(value >> 8))
            data.append(UInt8(value & 0xFF))
        } else {
            data.append(0xCE)
            data.append(UInt8(value >> 24))
            data.append(UInt8((value >> 16) & 0xFF))
            data.append(UInt8((value >> 8) & 0xFF))
            data.append(UInt8(value & 0xFF))
        }
    }
    
    private static func encodeInt(_ value: Int, to data: inout Data) throws {
        if value >= 0 {
            try encodeUInt32(UInt32(value), to: &data)
        } else if value >= -32 {
            data.append(UInt8(0x100 + value))
        } else if value >= -128 {
            data.append(0xD0)
            data.append(UInt8(bitPattern: Int8(value)))
        } else if value >= -32768 {
            data.append(0xD1)
            let int16Value = Int16(value)
            data.append(UInt8(int16Value >> 8))
            data.append(UInt8(int16Value & 0xFF))
        } else {
            data.append(0xD2)
            let int32Value = Int32(value)
            data.append(UInt8(int32Value >> 24))
            data.append(UInt8((int32Value >> 16) & 0xFF))
            data.append(UInt8((int32Value >> 8) & 0xFF))
            data.append(UInt8(int32Value & 0xFF))
        }
    }
    
    private static func decodeArray(from data: Data, offset: inout Int) throws -> [Any] {
        guard offset < data.count else { throw NvimClientError.invalidResponse("Unexpected end") }
        let format = data[offset]
        offset += 1
        let count: Int
        if format >= 0x90 && format <= 0x9F {
            count = Int(format - 0x90)
        } else if format == 0xDC {
            guard offset + 1 < data.count else { throw NvimClientError.invalidResponse("Unexpected end") }
            count = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2
        } else {
            throw NvimClientError.invalidResponse("Invalid array format")
        }
        var result: [Any] = []
        for _ in 0..<count { result.append(try decodeValue(from: data, offset: &offset)) }
        return result
    }
    
    private static func decodeValue(from data: Data, offset: inout Int) throws -> Any {
        guard offset < data.count else { throw NvimClientError.invalidResponse("Unexpected end") }
        let format = data[offset]
        if format <= 0x7F {
            offset += 1
            return Int(format)
        } else if format >= 0xE0 {
            offset += 1
            return Int(Int8(bitPattern: format))
        } else if format >= 0x80 && format <= 0x8F {
            return try decodeMap(from: data, offset: &offset)
        } else if format >= 0x90 && format <= 0x9F {
            return try decodeArray(from: data, offset: &offset)
        } else if format >= 0xA0 && format <= 0xBF {
            return try decodeString(from: data, offset: &offset)
        } else if format == 0xC0 {
            offset += 1
            return NSNull()
        } else if format == 0xC2 {
            offset += 1
            return false
        } else if format == 0xC3 {
            offset += 1
            return true
        } else if format == 0xD9 {
            return try decodeString8(from: data, offset: &offset)
        } else if format == 0xDA {
            return try decodeString16(from: data, offset: &offset)
        } else {
            throw NvimClientError.invalidResponse("Unsupported format: \(format)")
        }
    }
    
    private static func decodeMap(from data: Data, offset: inout Int) throws -> [String: Any] {
        let format = data[offset]
        offset += 1
        let count = Int(format - 0x80)
        var result: [String: Any] = [:]
        for _ in 0..<count {
            let key = try decodeValue(from: data, offset: &offset)
            let value = try decodeValue(from: data, offset: &offset)
            if let keyString = key as? String {
                result[keyString] = value
            } else {
                throw NvimClientError.invalidResponse("Map key must be string")
            }
        }
        return result
    }
    
    private static func decodeString(from data: Data, offset: inout Int) throws -> String {
        let format = data[offset]
        offset += 1
        let length = Int(format - 0xA0)
        guard offset + length <= data.count else { throw NvimClientError.invalidResponse("String length exceeds data") }
        let stringData = data[offset..<offset + length]
        offset += length
        guard let string = String(data: stringData, encoding: .utf8) else { throw NvimClientError.invalidResponse("Invalid UTF-8") }
        return string
    }
    
    private static func decodeString8(from data: Data, offset: inout Int) throws -> String {
        offset += 1
        guard offset < data.count else { throw NvimClientError.invalidResponse("Unexpected end") }
        let length = Int(data[offset])
        offset += 1
        guard offset + length <= data.count else { throw NvimClientError.invalidResponse("String length exceeds data") }
        let stringData = data[offset..<offset + length]
        offset += length
        guard let string = String(data: stringData, encoding: .utf8) else { throw NvimClientError.invalidResponse("Invalid UTF-8") }
        return string
    }
    
    private static func decodeString16(from data: Data, offset: inout Int) throws -> String {
        offset += 1
        guard offset + 1 < data.count else { throw NvimClientError.invalidResponse("Unexpected end") }
        let length = Int(data[offset]) << 8 | Int(data[offset + 1])
        offset += 2
        guard offset + length <= data.count else { throw NvimClientError.invalidResponse("String length exceeds data") }
        let stringData = data[offset..<offset + length]
        offset += length
        guard let string = String(data: stringData, encoding: .utf8) else { throw NvimClientError.invalidResponse("Invalid UTF-8") }
        return string
    }
}



enum NvimClientError: Error {
    case startupFailed(Error)
    case communicationFailed(String)
    case invalidResponse(String)
    case notRunning
}

