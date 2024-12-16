package main

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:os"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
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
        mem.tracking_allocator_destroy(&track)
    }

    test_input := os.read_entire_file("day06_test.txt") or_else panic("Failed to read test file.")
    defer delete(test_input)
    test_result := execute(transmute(string)test_input)
    fmt.printfln("Test input -> %v (expected 6)", test_result)
    
    file_path :: "day06_input.txt"
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
    lines: [dynamic]string
    defer delete(lines)
    width: int
    height: int
    {
        lines_split := strings.split_lines(input)
        defer delete(lines_split)
        
        for line in lines_split {
            if len(line) > 0 {
                if width != 0 do assert(len(line) == width)
                else do width = len(line)
                height += 1
                append(&lines, line)
            }
        }
    }
    
    Vec :: [2]int
    up :: Vec{0, -1}
    down :: Vec{0, 1}
    left :: Vec{-1, 0}
    right :: Vec{1, 0}
    
    guard_pos: Vec
    guard_dir: Vec
    for line, y in lines {
        for char, x in line {
            switch char {
            case '^':
                guard_pos = {x, y}
                guard_dir = up
            case 'v':
                guard_pos = {x, y}
                guard_dir = down
            case '<':
                guard_pos = {x, y}
                guard_dir = left
            case '>':
                guard_pos = {x, y}
                guard_dir = right
            }
        }
    }
    assert(guard_dir == up || guard_dir == down || guard_dir == left || guard_dir == right)
    
    original_guard_pos := guard_pos
    original_guard_dir := guard_dir
    
    original_path: [dynamic]Vec
    defer delete(original_path)
    
    was_visited :: proc(visited: []Vec, pos: Vec) -> bool {
        for other in visited {
            if other == pos do return true
        }
        return false
    }
    
    for {
        if !was_visited(original_path[:], guard_pos) {
            append(&original_path, guard_pos)
        }
        
        next_pos := guard_pos + guard_dir
        if next_pos.x < 0 || next_pos.x >= width || next_pos.y < 0 || next_pos.y >= height {
           break
        }
        
        if lines[next_pos.y][next_pos.x] == '#' {
            switch guard_dir {
                case up: guard_dir = right
                case right: guard_dir = down
                case down: guard_dir = left
                case left: guard_dir = up
            }
        }
        else {
            guard_pos = next_pos
        }
    }
    
    loop_count := 0
    
    PosDir :: struct { pos: Vec, dir: Vec }
    
    visited: [dynamic]PosDir
    defer delete(visited)
    
    for extra_obstacle in original_path {
        if extra_obstacle == original_guard_pos do continue
    
        was_visited :: proc(visited: []PosDir, pos_dir: PosDir) -> bool {
            for other in visited {
                if other == pos_dir do return true
            }
            return false
        }
        
        clear(&visited)
        
        guard_pos := original_guard_pos
        guard_dir := original_guard_dir
        
        for {
            if was_visited(visited[:], PosDir{ guard_pos, guard_dir }) {
                loop_count += 1
                break
            }
            else {
                append(&visited, PosDir{ guard_pos, guard_dir })
            }
        
            next_pos := guard_pos + guard_dir
            if next_pos.x < 0 || next_pos.x >= width || next_pos.y < 0 || next_pos.y >= height {
                break
            }
            
            if next_pos == extra_obstacle || lines[next_pos.y][next_pos.x] == '#' {
                switch guard_dir {
                    case up: guard_dir = right
                    case right: guard_dir = down
                    case down: guard_dir = left
                    case left: guard_dir = up
                }
            }
            else {
                guard_pos = next_pos
            }
        }
    }

    return loop_count
}
