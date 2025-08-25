#!/usr/bin/env python3

import subprocess
import msgpack
import time
import select
import os

def create_rpc_request(msg_id, method, params):
    """Create a MessagePack RPC request"""
    return [0, msg_id, method, params]

def send_rpc(process, msg_id, method, params):
    """Send RPC request and measure response time"""
    request = create_rpc_request(msg_id, method, params)
    data = msgpack.packb(request)
    
    print(f"Sending: {method} with params {params}")
    start_time = time.time()
    
    # Send request
    process.stdin.write(data)
    process.stdin.flush()
    
    # Read response with timeout
    try:
        # Wait for data to be available with 2 second timeout
        ready, _, _ = select.select([process.stdout], [], [], 2.0)
        if not ready:
            print("Timeout waiting for response")
            return None
            
        # Read available data
        data = os.read(process.stdout.fileno(), 4096)
        end_time = time.time()
        
        duration = end_time - start_time
        print(f"Response time: {duration:.6f} seconds")
        
        # Unpack the response
        response = msgpack.unpackb(data, raw=False)
        print(f"Response: {response}")
        return response
    except Exception as e:
        print(f"Error reading response: {e}")
        return None

def main():
    # Start nvim process
    cmd = [
        "/opt/homebrew/bin/nvim",
        "-n", "--headless", "--embed",
        "--cmd", "set noswapfile | set updatetime=50"
    ]
    
    print("Starting nvim process...")
    process = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    try:
        # Test various RPC calls
        msg_id = 1
        
        # First call - send input (usually fast)
        send_rpc(process, msg_id, "nvim_input", ["i"])
        msg_id += 1
        
        time.sleep(0.1)  # Small delay between calls
        
        # Subsequent calls - these should show the delay
        send_rpc(process, msg_id, "nvim_get_mode", [])
        msg_id += 1
        
        time.sleep(0.1)
        
        send_rpc(process, msg_id, "nvim_win_get_cursor", [0])
        msg_id += 1
        
        time.sleep(0.1)
        
        send_rpc(process, msg_id, "nvim_buf_get_lines", [0, 0, -1, False])
        msg_id += 1
        
    except KeyboardInterrupt:
        print("\nInterrupted by user")
    finally:
        print("Terminating nvim process...")
        process.terminate()
        process.wait()

if __name__ == "__main__":
    main()