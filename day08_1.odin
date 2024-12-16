package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer deinit_tracking_allocator(&track)

    test_input := os.read_entire_file("day08_test.txt") or_else panic("Failed to read test file.")
    defer delete(test_input)
    test_result := execute(transmute(string)test_input)
    fmt.printfln("Test input -> %v (expected 14)", test_result)
    
    // file_path :: "day07_input.txt"
    // input, file_ok := os.read_entire_file(file_path)
    // defer delete(input)
    // if !file_ok {
    //     fmt.printfln("Failed to read file '%v'", file_path)
    //     os.exit(1)
    // }
    // result := execute(transmute(string)input)
    // fmt.printfln("Real input -> %v", result)
}

execute :: proc(input: string) -> int {
    lines: [dynamic][]u8
    defer delete(lines)
    
    lines_split := strings.split_lines(input)
    defer delete(lines_split)
    
    for line in lines_split {
        if len(line) > 0 do append(&lines, transmute([]u8)line)
    }
    
    width := len(lines)
    height := len(lines[0])
    
    Pos :: [2]int
    
    antennas: map[u8][dynamic]Pos
    defer {
        for key in antennas do delete(antennas[key])
        delete(antennas)
    }
    
    for line, y in lines {
        for char, x in line {
            if char != '.' {
                if char not_in antennas do antennas[char] = nil
                append(&antennas[char], Pos{x, y})
            }
        }
    }

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
