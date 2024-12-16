package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day16_test1.txt", 7036 },
    { "day16_test2.txt", 11048 },
    { "day16_input.txt", nil },
}

Vec :: [2]int
Transform :: struct {
    pos: Vec,
    dir: Dir,
}
DirCosts :: [Dir]int
Plan :: struct($T: typeid) {
    data: [dynamic]T,
    width: int,
    height: int,
}
Dir :: enum { up, right, down, left }

dir_vec :: proc(dir: Dir) -> Vec {
    switch dir {
    case .up: return Vec{0, -1}
    case .down: return Vec{0, 1}
    case .left: return Vec{-1, 0}
    case .right: return Vec{1, 0}
    case: panic(fmt.tprint(dir))
    }
}

dir_next_clockwise :: proc(dir: Dir) -> Dir {
    return Dir((int(dir) + 1) % len(Dir))
}

dir_next_ccv :: proc(dir: Dir) -> Dir {
    return Dir((int(dir) + len(Dir) - 1) % len(Dir))
}

plan_at_ptr :: proc(using plan: ^Plan($T), pos: Vec) -> ^T {
    return &data[plan_index(plan^, pos)]
}

plan_at :: proc(using plan: Plan($T), pos: Vec) -> T {
    return data[plan_index(plan, pos)]
}

plan_in_bounds :: proc(using plan: Plan($T), pos: Vec) -> bool {
    return pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height
}

plan_index :: proc(using plan: Plan($T), pos: Vec) -> int {
    return pos.y * width + pos.x
}

execute :: proc(input: string) -> int {
    plan: Plan(u8)
    defer delete(plan.data)

    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        if plan.width != 0 do assert(len(line) == plan.width)
        plan.width = len(line)
        plan.height += 1
        append(&plan.data, ..transmute([]u8)line)
    }
    
    min_cost := Plan(DirCosts) {
        width = plan.width,
        height = plan.height,
    }
    defer delete(min_cost.data)
    
    start_pos: Vec
    end_pos: Vec
    for y in 0..<plan.height do for x in 0..<plan.width {
        pos := Vec{x, y}
        if plan_at(plan, pos) == 'S' do start_pos = pos
        if plan_at(plan, pos) == 'E' do end_pos = pos
        
        append(&min_cost.data, DirCosts {
            .up = max(int),
            .right = max(int),
            .down = max(int),
            .left = max(int),
        })
    }
    assert(start_pos != {})
    assert(end_pos != {})
    
    frontier: [dynamic]Transform
    defer delete(frontier)
    
    append(&frontier, Transform {
        pos = start_pos,
        dir = .right,
    })
    
    plan_at_ptr(&min_cost, start_pos)[.right] = 0
    
    for len(frontier) > 0 {
        current := pop(&frontier)
        current_cost := plan_at(min_cost, current.pos)[current.dir]
        
        candidates := []Transform {
            Transform {
                pos = current.pos,
                dir = dir_next_clockwise(current.dir),
            },
            Transform {
                pos = current.pos,
                dir = dir_next_ccv(current.dir),
            },
            Transform {
                pos = current.pos + dir_vec(current.dir),
                dir = current.dir,
            },
        }
        
        for candidate in candidates {
            if !plan_in_bounds(plan, candidate.pos) do continue
            assert(plan_in_bounds(min_cost, candidate.pos))
            if plan_at(plan, candidate.pos) == '#' do continue
            candidate_cost := current_cost + (1 if candidate.dir == current.dir else 1000)
            cost_ptr := plan_at_ptr(&min_cost, candidate.pos)
            if cost_ptr[candidate.dir] <= candidate_cost do continue
            cost_ptr[candidate.dir] = candidate_cost
            append(&frontier, candidate)
        }
    }
    
    min_target_cost := max(int)
    for cost in plan_at(min_cost, end_pos) {
        min_target_cost = min(min_target_cost, cost)
    }
    
    return min_target_cost
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
