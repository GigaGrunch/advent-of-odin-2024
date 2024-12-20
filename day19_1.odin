package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day19_test.txt", 6 },
    { "day19_input.txt", nil },
}

execute :: proc(input: string) -> int {
    available_patterns: [dynamic]string
    defer delete(available_patterns)
    
    requested_designs: [dynamic]string
    defer delete(requested_designs)

    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        if len(line) == 0 do continue
    
        if available_patterns == nil {
            pattern_it := line
            for pattern in strings.split_iterator(&pattern_it, ", ") {
                append(&available_patterns, pattern)
            }
        } else {
            append(&requested_designs, line)
        }
    }
    
    possible_designs := 0
    
    for design in requested_designs {
        remainders: [dynamic]string
        defer delete(remainders)
        append(&remainders, design)
        
        processed_remainders: map[string]struct{}
        defer delete(processed_remainders)
        
        for len(remainders) > 0 {
            slice.sort_by(remainders[:], proc(lhs, rhs: string) -> bool { return len(lhs) > len(rhs) })
        
            current_remainder := pop(&remainders)
            if current_remainder in processed_remainders do continue
            processed_remainders[current_remainder] = {}
            
            if len(current_remainder) == 0 {
                possible_designs += 1
                break
            }
            
            for pattern in available_patterns {
                if strings.starts_with(current_remainder, pattern) {
                    append(&remainders, current_remainder[len(pattern):])
                }
            }
        }
    }
    
    return possible_designs
}

main :: proc() {
    error_count := 0
    defer {
        fmt.printfln("error count: %v", error_count)
        os.exit(error_count)
    }

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer deinit_tracking_allocator(&track)
    
    for runner in runners {
        input, file_ok := os.read_entire_file(runner.file_path)
        defer delete(input)
        if !file_ok {
            fmt.printfln("Failed to read file '%v'", runner.file_path)
            error_count += 1
            continue
        }
        result := execute(transmute(string)input)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result {
                error_count += 1
                break
            }
        }
        fmt.println()
    }
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
