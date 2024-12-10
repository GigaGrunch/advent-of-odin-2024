package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day10_test1.txt", 1 },
    { "day10_test2.txt", 2 },
    { "day10_test3.txt", 4 },
    { "day10_test4.txt", 3 },
    { "day10_test5.txt", 36 },
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
    
    fmt.println("Map:")
    print(topo_map)
    
    raw_scores := make([]int, len(raw_map))
    defer delete(raw_scores)
    
    for &score in raw_scores {
        score = max(int)
    }
    
    scores := Map(int) {
        raw = raw_scores,
        height = map_height,
        width = map_width,
    }
    
    // calculate score for every position
    still_updating := true
    for still_updating {
        still_updating = false
    
        for y in 0..<map_height {
            for x in 0..<map_width {
                height := at(topo_map, x, y)
                score := at(scores, x, y)
                
                if height^ == '9' {
                    if set_score(score, 0) do still_updating = true
                    continue
                }
            
                neighbors := [][2]int { {x-1, y}, {x+1, y}, {x, y-1}, {x, y+1} }
                for neighbor in neighbors {
                    neighbor_exists := neighbor.x >= 0 && neighbor.x < map_width && neighbor.y >= 0 && neighbor.y < map_height
                    if neighbor_exists {
                        neighbor_height := at(topo_map, neighbor.x, neighbor.y)
                        neighbor_score := at(scores, neighbor.x, neighbor.y)
                        if neighbor_height^ == height^ + 1 && neighbor_score^ != max(int) {
                            if set_score(score, min(neighbor_score^ + 1, score^)) do still_updating = true
                        }
                    }
                }
            }
        }
    }
    
    fmt.println("Scores:")
    print(scores)

    return 0
}

set_score :: proc(ptr: ^int, score: int) -> bool {
    defer ptr^ = score
    return ptr^ != score
}

print :: proc(topo_map: Map($T)) {
    for value, i in topo_map.raw {
        if T == u8 do fmt.printf("%c ", value)
        else if value == max(T) do fmt.print(". ")
        else do fmt.printf("%v ", value)
        if (i + 1) % topo_map.width == 0 {
            fmt.println()
        }
    }
}

at :: proc(topo_map: Map($T), x, y: int) -> ^T {
    return &topo_map.raw[y * topo_map.width + x]
}

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
