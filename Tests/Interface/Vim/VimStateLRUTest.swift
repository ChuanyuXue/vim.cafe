/*
Author: <Chuanyu> (skewcy@gmail.com)
VimStateLRUTest.swift (c) 2025
Desc: Tests for VimStateLRU
Created:  2025-08-30T00:00:00.000Z
*/

import Testing
@testable import VimCafe

struct VimStateLRUTest {
    
    @Test func testBasicGetSet() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = [.h, .j, .k]
        let state = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        
        await cache.set(keystrokes, state)
        let retrieved = await cache.get(keystrokes)
        
        #expect(retrieved == state)
    }
    
    @Test func testGetNonExistentKey() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = [.h, .j, .k]
        
        let retrieved = await cache.get(keystrokes)
        #expect(retrieved == nil)
    }
    
    @Test func testLRUEviction() async throws {
        let cache = VimStateLRU(capacity: 2)
        
        let key1: [VimKeystroke] = [.h]
        let key2: [VimKeystroke] = [.j]
        let key3: [VimKeystroke] = [.k]
        
        let state1 = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        let state2 = VimState(buffer: ["line2"], cursor: VimCursor(row: 1, col: 0), mode: .insert)
        let state3 = VimState(buffer: ["line3"], cursor: VimCursor(row: 2, col: 0), mode: .visual)
        
        await cache.set(key1, state1)
        await cache.set(key2, state2)
        
        #expect(await cache.count() == 2)
        
        await cache.set(key3, state3)
        
        #expect(await cache.count() == 2)
        #expect(await cache.get(key1) == nil)
        #expect(await cache.get(key2) == state2)
        #expect(await cache.get(key3) == state3)
    }
    
    @Test func testAccessUpdatesOrder() async throws {
        let cache = VimStateLRU(capacity: 2)
        
        let key1: [VimKeystroke] = [.h]
        let key2: [VimKeystroke] = [.j]
        let key3: [VimKeystroke] = [.k]
        
        let state1 = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        let state2 = VimState(buffer: ["line2"], cursor: VimCursor(row: 1, col: 0), mode: .insert)
        let state3 = VimState(buffer: ["line3"], cursor: VimCursor(row: 2, col: 0), mode: .visual)
        
        await cache.set(key1, state1)
        await cache.set(key2, state2)
        
        _ = await cache.get(key1)
        
        await cache.set(key3, state3)
        
        #expect(await cache.get(key1) == state1)
        #expect(await cache.get(key2) == nil)
        #expect(await cache.get(key3) == state3)
    }
    
    @Test func testUpdateExistingKey() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = [.h, .j, .k]
        let state1 = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        let state2 = VimState(buffer: ["line2"], cursor: VimCursor(row: 1, col: 0), mode: .insert)
        
        await cache.set(keystrokes, state1)
        #expect(await cache.count() == 1)
        
        await cache.set(keystrokes, state2)
        #expect(await cache.count() == 1)
        
        let retrieved = await cache.get(keystrokes)
        #expect(retrieved == state2)
    }
    
    @Test func testRemove() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = [.h, .j, .k]
        let state = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        
        await cache.set(keystrokes, state)
        #expect(await cache.count() == 1)
        
        await cache.remove(keystrokes)
        #expect(await cache.count() == 0)
        #expect(await cache.get(keystrokes) == nil)
    }
    
    @Test func testClear() async throws {
        let cache = VimStateLRU(capacity: 3)
        let key1: [VimKeystroke] = [.h]
        let key2: [VimKeystroke] = [.j]
        let state = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        
        await cache.set(key1, state)
        await cache.set(key2, state)
        #expect(await cache.count() == 2)
        
        await cache.clear()
        #expect(await cache.count() == 0)
        #expect(await cache.get(key1) == nil)
        #expect(await cache.get(key2) == nil)
    }
    
    @Test func testEmptyKeystrokes() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = []
        let state = VimState(buffer: ["line1"], cursor: VimCursor(row: 0, col: 0), mode: .normal)
        
        await cache.set(keystrokes, state)
        let retrieved = await cache.get(keystrokes)
        
        #expect(retrieved == state)
    }
    
    @Test func testComplexKeystrokes() async throws {
        let cache = VimStateLRU(capacity: 3)
        let keystrokes: [VimKeystroke] = [.escape, .colon, .w, .enter]
        let state = VimState(buffer: ["line1", "line2"], cursor: VimCursor(row: 1, col: 5), mode: .command)
        
        await cache.set(keystrokes, state)
        let retrieved = await cache.get(keystrokes)
        
        #expect(retrieved == state)
    }
}