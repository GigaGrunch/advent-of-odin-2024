package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day12_test1.txt", 80 },
    // { "day12_test2.txt", 436 },
    // { "day12_test4.txt", 236 },
    // { "day12_test5.txt", 368 },
    // { "day12_test3.txt", 1206 },
    // { "day12_input.txt", nil },
}

Plot_Map :: struct {
    plants: [dynamic]u8,
    visited: []b8,
    width: int,
    height: int,
}

Vec :: [2]int

Fence_Side :: enum { top, bottom, left, right }

Region_Edge :: struct {
    side: Fence_Side,
    start: Vec,
    end: Vec,
    positions: [dynamic]Vec,
}

execute :: proc(input: string) -> int {
    plot_map: Plot_Map
    defer delete(plot_map.plants)
    
    input_mut := input
    for line in strings.split_lines_iterator(&input_mut) {
        for i in 0..<len(line) do append(&plot_map.plants, line[i])
        assert(plot_map.width == 0 || len(line) == plot_map.width)
        plot_map.width = len(line)
        plot_map.height += 1
    }
    
    plot_map.visited = make([]b8, len(plot_map.plants))
    defer delete(plot_map.visited)
    
    total_cost := 0
    
    print(plot_map)
    
    for has_unvisited(plot_map.visited) {
        region_plant: u8
        frontier: [dynamic]Vec
        defer delete(frontier)
        
        for &visited, i in plot_map.visited {
            if !visited {
                region_plant = plot_map.plants[i]
                visited = true
                append(&frontier, Vec{ i % plot_map.width, i / plot_map.width })
                break
            }
        }
        
        region_area := 0
        region_edges: [dynamic]Region_Edge
        defer {
            for edge in region_edges do delete(edge.positions)
            delete(region_edges)
        }
        
        for len(frontier) > 0 {
            pos := pop(&frontier)
            visited := get_visited(&plot_map, pos)
            assert(visited^ == true, fmt.tprintf("region_plant: %v, pos: %v", region_plant, pos))
            assert(region_plant == get_plant(plot_map, pos))
            
            region_area += 1
            neighbors := []Vec { {pos.x - 1, pos.y}, {pos.x + 1, pos.y}, {pos.x, pos.y - 1}, {pos.x, pos.y + 1} }
            for neighbor in neighbors {
                out_of_bounds := neighbor.x < 0 || neighbor.x >= plot_map.width || neighbor.y < 0 || neighbor.y >= plot_map.height
                if !out_of_bounds && get_plant(plot_map, neighbor) == region_plant {
                    neighbor_visited := get_visited(&plot_map, neighbor)
                    if !neighbor_visited^ {
                        neighbor_visited^ = true
                        append(&frontier, neighbor)
                    }
                } else {
                    fence_side: Fence_Side
                    switch neighbor.x {
                    case pos.x - 1: fence_side = .left
                    case pos.x + 1: fence_side = .right
                    }
                    switch neighbor.y {
                    case pos.y - 1: fence_side = .top
                    case pos.y + 1: fence_side = .bottom
                    }
                    
                    edge_index := 0
                    outer: for ;edge_index < len(region_edges); edge_index += 1 {
                        edge := &region_edges[edge_index]
                        if edge.side != fence_side do continue
                        
                        for other in edge.positions {
                            if other == pos do break outer
                        }
                        
                        if fence_side == .top || fence_side == .bottom {
                            if edge.start.y != pos.y do continue
                            if edge.start.x - 1 == pos.x {
                                edge.start.x = pos.x
                                append(&edge.positions, pos)
                                break outer
                            }
                            if edge.end.x + 1 == pos.x {
                                edge.end.x = pos.x
                                append(&edge.positions, pos)
                                break outer
                            }
                        } else {
                            if edge.start.x != pos.x do continue
                            if edge.start.y - 1 == pos.y {
                                edge.start.y = pos.y
                                append(&edge.positions, pos)
                                break outer
                            }
                            if edge.end.y + 1 == pos.y {
                                edge.end.y = pos.y
                                append(&edge.positions, pos)
                                break outer
                            }
                        }
                    }
                    if edge_index == len(region_edges) {
                        edge := Region_Edge{
                            side = fence_side,
                            start = pos,
                            end = pos,
                        }
                        append(&edge.positions, pos)
                        append(&region_edges, edge)
                    }
                }
            }
        }
        
        fmt.printf("%c  ", region_plant)
        for edge in region_edges {
            using edge
            fmt.printf("(%v,%v) -%v-> (%v,%v)  ", start.x, start.y, side, end.x, end.y)
        }
        fmt.println()
        
        region_cost := region_area * len(region_edges)
        total_cost += region_cost
    }

    return total_cost
}

print :: proc(using plot_map: Plot_Map) {
    for plant, i in plants {
        fmt.printf("%c", plant)
        fmt.print("\n" if (i + 1) % width == 0 else " ")
    }
}

get_visited :: proc(using plot_map: ^Plot_Map, pos: Vec) -> ^b8 {
    return &visited[pos.y * width + pos.x]
}

get_plant :: proc(using plot_map: Plot_Map, pos: Vec) -> u8 {
    return plants[pos.y * width + pos.x]
}

has_unvisited :: proc(visited: []b8) -> bool {
    for it in visited do if !it do return true
    return false
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
