package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"

runners := []struct{file_path: string, dimensions: Vec, iteration_count: int, expected_result: Maybe(int)} {
    { "day18_test.txt", Vec{7, 7}, 12, 22 },
    { "day18_input.txt", Vec{71, 71}, 1024, nil },
}

Vec :: [2]int
UP :: Vec{0, -1}
DOWN :: Vec{0, 1}
LEFT :: Vec{-1, 0}
RIGHT :: Vec{1, 0}
DIRS :: []Vec { UP, DOWN, LEFT, RIGHT }

execute :: proc(input: string, dimensions: Vec, it_count: int) -> int {
    field_map := make([]u8, dimensions.x * dimensions.y)
    defer delete(field_map)
    
    slice.fill(field_map, '.')
    
    it := 0
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        coord_it := line
        coord := Vec {
            strconv.atoi(strings.split_iterator(&coord_it, ",") or_else panic(line)),
            strconv.atoi(strings.split_iterator(&coord_it, ",") or_else panic(line)),
        }
        at_ptr(field_map, dimensions, coord)^ = '#'
        it += 1
        if it == it_count do break
    }
    
    start_pos := Vec{0, 0}
    end_pos := Vec{dimensions.x - 1, dimensions.y - 1}
    
    frontier: map[Vec]struct{}
    defer delete(frontier)
    frontier[start_pos] = {}
    
    g_scores := make([]int, dimensions.x * dimensions.y)
    defer delete(g_scores)
    slice.fill(g_scores, max(int))
    at_ptr(g_scores, dimensions, start_pos)^ = 0
    
    f_scores := make([]int, dimensions.x * dimensions.y)
    defer delete(f_scores)
    slice.fill(f_scores, max(int))
    at_ptr(f_scores, dimensions, start_pos)^ = heuristic(start_pos, end_pos)
    
    for len(frontier) > 0 {
        f_score := max(int)
        pos: Vec
        for frontier_pos in frontier {
            score := at(f_scores, dimensions, frontier_pos)
            if score < f_score {
                f_score = score
                pos = frontier_pos
            }
        }
        
        if pos == end_pos do break
    
        g_score := at(g_scores, dimensions, pos)
        
        delete_key(&frontier, pos)
        
        for dir in DIRS {
            neighbor := pos + dir
            if out_of_bounds(neighbor, dimensions) do continue
            is_blocked := at(field_map, dimensions, neighbor) == '#'
            if is_blocked do continue
            
            neighbor_g_score := at_ptr(g_scores, dimensions, neighbor)
            tentative_g_score := g_score + 1
            if tentative_g_score >= neighbor_g_score^ do continue
            
            neighbor_g_score^ = tentative_g_score
            neighbor_f_score := at_ptr(f_scores, dimensions, neighbor)
            neighbor_f_score^ = tentative_g_score + heuristic(neighbor, end_pos)
            
            frontier[neighbor] = {}
        }
    }
    
    return at(g_scores, dimensions, end_pos)
}

heuristic :: proc(pos, end_pos: Vec) -> int {
    return abs(pos.x - end_pos.x) + abs(pos.y - end_pos.y)
}

at_ptr :: proc(list: []$T, dimensions, pos: Vec) -> ^T {
    return &list[pos.y * dimensions.x + pos.x]
}

at :: proc(list: []$T, dimensions, pos: Vec) -> T {
    return list[pos.y * dimensions.x + pos.x]
}

out_of_bounds :: proc(pos, dimensions: Vec) -> bool {
    return pos.x < 0 || pos.x >= dimensions.x || pos.y < 0 || pos.y >= dimensions.y
}

draw_map :: proc(field_map: []u8, dimensions: Vec) {
    for y in 0..<dimensions.y {
        for x in 0..<dimensions.x {
            fmt.printf("%c", at(field_map, dimensions, Vec{x, y}))
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
        result := execute(transmute(string)input, runner.dimensions, runner.iteration_count)
        
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
