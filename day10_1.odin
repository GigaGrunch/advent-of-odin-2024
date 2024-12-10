package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := [?]struct{file_path: string, expected_result: Maybe(int)} {
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
    
    height: int
    width: int
    for line in lines {
        if len(line) > 0 {
            append(&raw_map, ..transmute([]u8)line)
            assert(width == 0 || len(line) == width)
            height += 1
            width = len(line)
        }
    }
    
    topo_map := Map {
        raw = raw_map[:],
        height = height,
        width = width,
    }
    
    print(topo_map)

    return 0
}

print :: proc(topo_map: Map) {
    for char, i in topo_map.raw {
        fmt.printf("%c", char)
        if (i + 1) % topo_map.width == 0 {
            fmt.println()
        }
    }
}

at :: proc(topo_map: Map, x, y: int) -> u8 {
    return topo_map.raw[y * topo_map.width + x]
}

Map :: struct {
    raw: []u8,
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
