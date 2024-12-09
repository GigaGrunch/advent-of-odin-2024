package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

test_path :: "day??_test.txt"
expected_test_result :: ??
input_path :: "day??_input.txt"

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
    return 0
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
