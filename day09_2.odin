package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

test_path :: "day09_test.txt"
expected_test_result :: 2858
input_path :: "day09_input.txt"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer deinit_tracking_allocator(&track)

    test_input, test_ok := os.read_entire_file(test_path)
    defer delete(test_input)
    if !test_ok {
        fmt.printfln("Failed to read file '%v'", test_path)
        os.exit(1)
    }
    test_result := execute(test_input)
    fmt.printfln("Test input -> %v (expected %v)", test_result, expected_test_result)
    
    input, file_ok := os.read_entire_file(input_path)
    defer delete(input)
    if !file_ok {
        fmt.printfln("Failed to read file '%v'", input_path)
        os.exit(1)
    }
    result := execute(transmute(string)input)
    fmt.printfln("Real input -> %v", result)
}

execute :: proc{execute_bytes, execute_string}

execute_bytes :: proc(input: []u8) -> int {
    return execute_string(transmute(string)input)
}

execute_string :: proc(input: string) -> int {
    block_layout: [dynamic]int
    defer delete(block_layout)
    
    empty_space: [dynamic]int
    defer delete(empty_space)

    // build initial block layout
    for i in 0..<len(input) {
        char := input[i]
        switch char {
            case '0'..='9': {}
            case: break
        }
        
        file_id := -1
        block_length := char - '0'
        
        if i % 2 == 0 do file_id = i / 2
        
        for j in 0..<block_length {
            append(&block_layout, file_id)
            append(&empty_space, -1)
        }
    }
    
    // select whole files from the right and find fitting gaps from the left
    for right_index := len(block_layout) - 1; right_index >= 0; {
        file_id := block_layout[right_index]
        if file_id == -1 {
            right_index -= 1
            continue
        }
        
        file_start := right_index + 1
        file_end := right_index + 1
        for ;right_index >= 0; right_index -= 1 {
            if block_layout[right_index] != file_id {
                file_start = right_index + 1
                break
            }
        }
        file_size := file_end - file_start
        
        for left_index := 0; left_index < file_start; {
            if block_layout[left_index] != -1 {
                left_index += 1
                continue
            }
            
            gap_start := left_index
            gap_end := left_index
            for ;left_index < file_start; left_index += 1 {
                if block_layout[left_index] != -1 {
                    gap_end = left_index
                    break
                }
            }
            gap_size := gap_end - gap_start
            
            if gap_size >= file_size {
                copy(block_layout[gap_start:][:file_size], block_layout[file_start:][:file_size])
                copy(block_layout[file_start:][:file_size], empty_space[:file_size])
                break
            }
        }
    }
    
    // calculate the checksum
    checksum := 0
    for slot, i in block_layout {
        if slot != -1 do checksum += i * slot
    }
    return checksum
}

print_progress :: proc(progress: f32) {
    fmt.printf("  %v%%  \r", int(progress * 100))
}

deinit_tracking_allocator :: proc(track: ^mem.Tracking_Allocator) {
    if len(track.allocation_map) > 0 {
        fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
        for _, entry in track.allocation_map {
            fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
        }
    }
    if len(track.bad_free_array) > 0 {
        fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
        for entry in track.bad_free_array {
            fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
        }
    }
    mem.tracking_allocator_destroy(track)
}
