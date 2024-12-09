package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

test_path :: "day09_test.txt"
expected_test_result :: 1928
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
        }
    }
    
    // fill all gaps by taking used slots from the right and filling free slots on the left
    free_slot_index := 0
    used_slot_index := len(block_layout) - 1
    for ;used_slot_index > free_slot_index; used_slot_index -= 1 {
        used_slot := block_layout[used_slot_index]
        if used_slot == -1 do continue
        
        for ;free_slot_index < used_slot_index; free_slot_index += 1 {
            free_slot := block_layout[free_slot_index]
            if free_slot == -1 {
                block_layout[free_slot_index] = used_slot
                block_layout[used_slot_index] = -1
                break
            }
        }
    }
    
    // calculate the checksum
    checksum := 0
    for slot, i in block_layout {
        if slot == -1 do break
        checksum += i * slot
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
