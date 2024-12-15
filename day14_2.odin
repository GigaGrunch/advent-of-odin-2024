package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"
import "core:slice"

runners := []struct{file_path: string, map_dimensions: Vec, expected_result: Maybe(int)} {
    { "day14_input.txt", Vec{101, 103}, nil },
}

Vec :: [2]int
ARRAY_LENGTH :: 500

execute :: proc(input: string, map_dimensions: Vec) -> int {
    bot_count := 0
    start_positions: [ARRAY_LENGTH]Vec
    velocities: [ARRAY_LENGTH]Vec
    
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        value_it := line
        for value_str in strings.split_iterator(&value_it, " ") {
            xy_it := value_str[2:]
            x_str := strings.split_iterator(&xy_it, ",") or_else panic(line)
            y_str := strings.split_iterator(&xy_it, ",") or_else panic(line)
            x := strconv.atoi(x_str)
            y := strconv.atoi(y_str)
            switch value_str[0] {
            case 'p': start_positions[bot_count] = Vec{x, y}
            case 'v': velocities[bot_count] = Vec{x, y}
            case: panic(line)
            }
        }
    
        bot_count += 1
    }
    
    positions := start_positions
    
    map_dimensions_array: [ARRAY_LENGTH]Vec
    slice.fill(map_dimensions_array[:], map_dimensions)
    
    middle_pos := map_dimensions / 2
    
    up := Vec{0, -1}
    down := Vec{0, 1}
    left := Vec{-1, 0}
    right := Vec{1, 0}
    
    min_no_neighbors := max(int)
    min_no_neighbors_i: int
    
    for it_count := 1; true; it_count += 1 {
        positions = (positions + velocities + map_dimensions_array) % map_dimensions_array
        
        no_neighbor_count := 0
        outer: for pos in positions[:bot_count] {
            neighbors := [4]Vec {
                (pos + up + map_dimensions) % map_dimensions,
                (pos + down + map_dimensions) % map_dimensions,
                (pos + left + map_dimensions) % map_dimensions,
                (pos + right + map_dimensions) % map_dimensions,
            }
            for other in positions[:bot_count] {
                for neighbor in neighbors {
                    if neighbor == other do continue outer
                }
            }
            no_neighbor_count += 1
        }
        
        if no_neighbor_count < min_no_neighbors {
            min_no_neighbors = no_neighbor_count
            min_no_neighbors_i = it_count
        }
        
        if positions == start_positions {
            fmt.printfln("loop after %v iterations", it_count)
            break
        }
    }
    
    positions = start_positions
    for _ in 1..=min_no_neighbors_i {
        positions = (positions + velocities + map_dimensions_array) % map_dimensions_array
    }
    print(positions[:bot_count], map_dimensions)

    return min_no_neighbors_i
}

print :: proc(positions: []Vec, map_dimensions: Vec) {
    for y in 0..<map_dimensions.y {
        horizontal: for x in 0..<map_dimensions.x {
            pos := Vec{x, y}
            for bot_pos in positions {
                if pos == bot_pos {
                    fmt.print("O")
                    continue horizontal
                }
            }
            fmt.print(".")
        }
        fmt.println()
    }
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
        result := execute(transmute(string)input, runner.map_dimensions)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result do error_count += 1
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
