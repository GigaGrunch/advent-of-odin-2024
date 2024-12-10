package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day10_test6.txt", 3 },
    { "day10_test7.txt", 13 },
    { "day10_test8.txt", 227 },
    { "day10_test5.txt", 81 },
    { "day10_input.txt", nil },
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
        result := execute(input)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result do error_count += 1
        }
        fmt.println()
    }
}

execute :: proc{execute_bytes, execute_string}

execute_bytes :: proc(input: []u8) -> int {
    return execute_string(transmute(string)input)
}

execute_string :: proc(input: string) -> int {
    raw_map: [dynamic]u8
    defer delete(raw_map)
    
    lines := strings.split_lines(input)
    defer delete(lines)
    
    // build map
    map_height: int
    map_width: int
    for line in lines {
        if len(line) > 0 {
            append(&raw_map, ..transmute([]u8)line)
            assert(map_width == 0 || len(line) == map_width)
            map_height += 1
            map_width = len(line)
        }
    }
    
    topo_map := Map(u8) {
        raw = raw_map[:],
        height = map_height,
        width = map_width,
    }
    
    // calculate unique paths
    complete_paths: [dynamic]Path
    defer delete(complete_paths)
    
    frontier: [dynamic]Path
    defer delete(frontier)
    
    for y in 0..<map_height {
        for x in 0..<map_width {
            height := at(topo_map, x, y)^
            if height == '9' {
                path: Path
                path[0] = {x, y}
                for &pos in path[1:] do pos = {-1, -1}
                append(&frontier, path)
            }
        }
    }
    
    for len(frontier) > 0 {
        path := pop(&frontier)
        current_index: int
        for ;current_index < len(path); current_index += 1 {
            if path[current_index] == {-1, -1} {
                current_index -= 1
                break
            }
        }
        
        if current_index == len(path) {
            append(&complete_paths, path)
            continue
        }
        
        pos := path[current_index]
        height := at(topo_map, pos)^
        neighbors := []Vec { {pos.x-1, pos.y}, {pos.x+1, pos.y}, {pos.x, pos.y-1}, {pos.x, pos.y+1} }
        for neighbor in neighbors {
            neighbor_exists := neighbor.x >= 0 && neighbor.x < map_width && neighbor.y >= 0 && neighbor.y < map_height
            if neighbor_exists {
                neighbor_height := at(topo_map, neighbor)^
                if neighbor_height + 1 == height {
                    neighbor_path := path
                    neighbor_path[current_index + 1] = neighbor
                    append(&frontier, neighbor_path)
                }
            }
        }
    }

    return len(complete_paths)
}

print :: proc(some_map: Map($T)) {
    for value, i in some_map.raw {
        if T == u8 do fmt.printf("%c ", value)
        else if value == max(T) do fmt.print(". ")
        else do fmt.printf("%v ", value)
        if (i + 1) % some_map.width == 0 {
            fmt.println()
        }
    }
}

at :: proc{at_pos, at_ints}

at_pos :: proc(some_map: Map($T), pos: Vec) -> ^T {
    return at_ints(some_map, pos.x, pos.y)
}

at_ints :: proc(some_map: Map($T), x, y: int) -> ^T {
    return &some_map.raw[y * some_map.width + x]
}

Vec :: [2]int
Path :: [10]Vec

Map :: struct($T: typeid) {
    raw: []T,
    width, height: int,
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
