package main

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:os"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day15_test1.txt", 2028 },
    { "day15_test2.txt", 10092 },
    { "day15_input.txt", nil },
}

Vec :: [2]int
Warehouse :: struct {
    data: [dynamic]u8,
    width, height: int,
}
UP := Vec{0, -1}
DOWN := Vec{0, 1}
LEFT := Vec{-1, 0}
RIGHT := Vec{1, 0}

execute :: proc(input: string) -> int {
    warehouse: Warehouse
    defer delete(warehouse.data)
    
    robo_pos: Vec
    
    lines_it := input
    for line in strings.split_lines_iterator(&lines_it) {
        if len(line) == 0 do break
        
        if warehouse.width == 0 do warehouse.width = len(line)
        else do assert(len(line) == warehouse.width, line)
        warehouse.height += 1
        
        append(&warehouse.data, ..transmute([]u8)line)
    }
    
    for y in 0..<warehouse.height do for x in 0..<warehouse.width {
        pos := Vec{x, y}
        if warehouse_at(&warehouse, pos)^ == '@' do robo_pos = Vec{x, y}
    }
    
    moves: [dynamic]Vec
    defer delete(moves)
    
    for char in transmute([]u8)lines_it {
        switch char {
        case '^': append(&moves, UP)
        case 'v': append(&moves, DOWN)
        case '<': append(&moves, LEFT)
        case '>': append(&moves, RIGHT)
        }
    }
    
    for move in moves {
        pos := robo_pos
        loop: for ;;pos += move {
            switch warehouse_at(warehouse, pos) {
            case '@', 'O': continue loop
            case '.', '#': break loop
            case: panic("Unexpected character")
            }
        }
        
        move_is_valid := warehouse_at(warehouse, pos) != '#'
        if move_is_valid {
            for ;pos != robo_pos; pos -= move {
                here := warehouse_at(&warehouse, pos)
                there := warehouse_at(&warehouse, pos - move)
                assert(here^ == '.')
                here^ = there^
                there^ = '.'
            }
            robo_pos += move
        }
    }
    
    result := 0
    
    for char, i in warehouse.data {
        if char == 'O' {
            pos := Vec{i % warehouse.width, i / warehouse.width}
            gps_coordinate := pos.x + 100 * pos.y
            result += gps_coordinate
        }
    }
    
    return result
}

warehouse_at :: proc{warehouse_at_val, warehouse_at_ptr}

warehouse_at_val :: proc(using warehouse: Warehouse, pos: Vec) -> u8 {
    return data[pos.y * width + pos.x]
}

warehouse_at_ptr :: proc(using warehouse: ^Warehouse, pos: Vec) -> ^u8 {
    return &data[pos.y * width + pos.x]
}

warehouse_print :: proc(using warehouse: Warehouse) {
    for y in 0..<height do for x in 0..<width {
        fmt.printf("%c", data[y * width + x])
        if (x + 1) % width == 0 do fmt.println()
    }
}

moves_print :: proc(moves: []Vec) {
    for move in moves {
        move_print(move)
        fmt.print(" ")
    }
    fmt.println()
}

move_print :: proc(move: Vec) {
    switch move {
    case UP: fmt.print("up")
    case DOWN: fmt.print("down")
    case LEFT: fmt.print("left")
    case RIGHT: fmt.print("right")
    case: panic(fmt.tprint(move))
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
