package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day21_test.txt", 126384 },
    { "day21_input.txt", nil },
}

Vec :: [2]int

execute :: proc(input: string) -> int {
    number_keypad := map[u8]Vec {
        '7' = Vec{0, 0},
        '8' = Vec{1, 0},
        '9' = Vec{2, 0},
        '4' = Vec{0, 1},
        '5' = Vec{1, 1},
        '6' = Vec{2, 1},
        '1' = Vec{0, 2},
        '2' = Vec{1, 2},
        '3' = Vec{2, 2},
        'x' = Vec{0, 3},
        '0' = Vec{1, 3},
        'A' = Vec{2, 3},
    }
    defer delete(number_keypad)
    
    dir_keypad := map[u8]Vec {
        'x' = Vec{0, 0},
        '^' = Vec{1, 0},
        'A' = Vec{2, 0},
        '<' = Vec{0, 1},
        'v' = Vec{1, 1},
        '>' = Vec{2, 1},
    }
    defer delete(dir_keypad)

    line_it := input
    for number_code in strings.split_lines_iterator(&line_it) {
        fmt.print(number_code, "-> ")
        defer fmt.println()
        
        keypad := number_keypad
        pos := keypad['A']
        forbidden_pos := keypad['x']
        
        key_presses: [dynamic]u8
        defer delete(key_presses)
        
        for char in transmute([]u8)number_code {
            char_pos := keypad[char]
            
            first_axis := 0 if pos.x == forbidden_pos.x else 1
            second_axis := (first_axis + 1) % 2
            axes := []int{first_axis, second_axis}
            for axis in axes {
                diff := char_pos[axis] - pos[axis]
                dir: Vec
                dir[axis] = 1 if diff > 0 else -1
                
                key_press: u8
                switch dir {
                case Vec{0, -1}: key_press = '^'
                case Vec{0, 1}: key_press = 'v'
                case Vec{-1, 0}: key_press = '<'
                case Vec{1, 0}: key_press = '>'
                }
                
                for ;abs(diff) > 0; diff = char_pos[axis] - pos[axis] {
                    pos += dir
                    append(&key_presses, key_press)
                }
            }
            
            append(&key_presses, 'A')
        }
        
        fmt.print(transmute(string)key_presses[:])
    }
    return 0
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
        defer fmt.println()
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result {
                error_count += 1
                break
            }
        }
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
