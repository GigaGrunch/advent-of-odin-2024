package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer deinit_tracking_allocator(&track)

    test_input := os.read_entire_file("day08_test.txt") or_else panic("Failed to read test file.")
    defer delete(test_input)
    test_result := execute(transmute(string)test_input)
    fmt.printfln("Test input -> %v (expected 34)", test_result)
    
    file_path :: "day08_input.txt"
    input, file_ok := os.read_entire_file(file_path)
    defer delete(input)
    if !file_ok {
        fmt.printfln("Failed to read file '%v'", file_path)
        os.exit(1)
    }
    result := execute(transmute(string)input)
    fmt.printfln("Real input -> %v", result)
}

execute :: proc(input: string) -> int {
    lines: [dynamic][]u8
    defer delete(lines)
    
    lines_split := strings.split_lines(input)
    defer delete(lines_split)
    
    for line in lines_split {
        if len(line) > 0 do append(&lines, transmute([]u8)line)
    }
    
    bounds := Vec{len(lines), len(lines[0])}
    
    antennas: map[u8][dynamic]Vec
    defer {
        for key in antennas do delete(antennas[key])
        delete(antennas)
    }
    
    for line, y in lines {
        for char, x in line {
            if char != '.' {
                if char not_in antennas do antennas[char] = nil
                append(&antennas[char], Vec{x, y})
            }
        }
    }
    
    antinodes: map[Vec]u8
    defer delete(antinodes)
    
    for key in antennas {
        key_antennas := antennas[key]
        for antenna_a, i in key_antennas[:len(key_antennas) - 1] {
            for antenna_b in key_antennas[i + 1:] {
                pos_diff := antenna_a - antenna_b
                for antinode := antenna_a; in_bounds(bounds, antinode); antinode += pos_diff {
                    antinodes[antinode] = 1
                }
                for antinode := antenna_b; in_bounds(bounds, antinode); antinode -= pos_diff {
                    antinodes[antinode] = 1
                }
            }
        }
    }

    return len(antinodes)
}

Vec :: [2]int

in_bounds :: proc(bounds: Vec, pos: Vec) -> bool {
    return pos.x >= 0 && pos.x < bounds.x && pos.y >= 0 && pos.y < bounds.y
}

@(test)
test_in_bounts :: proc(t: ^testing.T) {
    testing.expect_value(t, in_bounds({10, 10}, {0, 0}), true)
    testing.expect_value(t, in_bounds({10, 10}, {-1, 0}), false)
    testing.expect_value(t, in_bounds({10, 10}, {0, -1}), false)
    testing.expect_value(t, in_bounds({10, 10}, {9, 9}), true)
    testing.expect_value(t, in_bounds({10, 10}, {10, 9}), false)
    testing.expect_value(t, in_bounds({10, 10}, {9, 10}), false)
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
