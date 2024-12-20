package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day19_test.txt", 16 },
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
    
    solution_count := 0
    
    for design in requested_designs {
        FrontierElement :: struct { remainder: string, parent: FrontierIndex }
        FrontierIndex :: struct { frontier_elements: ^[dynamic]FrontierElement, value: int }
        get :: proc (using index: FrontierIndex) -> ^FrontierElement { return &frontier_elements[value] if frontier_elements != nil else nil }
        
        frontier_elements: [dynamic]FrontierElement
        defer delete(frontier_elements)
        append(&frontier_elements, FrontierElement{ design, {} })
        
        frontier: [dynamic]FrontierIndex
        defer delete(frontier)
        append(&frontier, FrontierIndex{ &frontier_elements, 0 })
        
        processed_remainders: map[string]int
        defer delete(processed_remainders)
        
        for len(frontier) > 0 {
            slice.sort_by(frontier[:], proc(lhs, rhs: FrontierIndex) -> bool { return len(get(lhs).remainder) > len(get(rhs).remainder) })
        
            current_index := pop(&frontier)
            current := get(current_index)
            if current.remainder in processed_remainders {
                value := processed_remainders[current.remainder]
                for it := get(current.parent); it != nil; it = get(it.parent) {
                    processed_remainders[it.remainder] += value
                }
                continue
            }
            
            processed_remainders[current.remainder] = 0
            
            for pattern in available_patterns {
                if strings.starts_with(current.remainder, pattern) {
                    remainder := current.remainder[len(pattern):]
                    if len(remainder) == 0 {
                        for it := current; it != nil; it = get(it.parent) {
                            processed_remainders[it.remainder] += 1
                        }
                    } else {
                        index := len(frontier_elements)
                        append(&frontier_elements, FrontierElement{ remainder, current_index })
                        append(&frontier, FrontierIndex { &frontier_elements, index })
                    }
                }
            }
        }
        
        solution_count += processed_remainders[design]
    }
    
    return solution_count
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
