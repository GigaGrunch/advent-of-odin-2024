package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:strconv"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day21_test.txt", 126384 },
    { "day21_input.txt", nil },
}

Vec :: [2]int
UP :: Vec{0, -1}
DOWN :: Vec{0, 1}
LEFT :: Vec{-1, 0}
RIGHT :: Vec{1, 0}

get_number_keypad :: proc() -> map[u8]Vec {
    return map[u8]Vec {
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
}

get_dir_keypad :: proc() -> map[u8]Vec {
    return map[u8]Vec {
        'x' = Vec{0, 0},
        '^' = Vec{1, 0},
        'A' = Vec{2, 0},
        '<' = Vec{0, 1},
        'v' = Vec{1, 1},
        '>' = Vec{2, 1},
    }
}

simulate :: proc(type: string, input: string) {
    keypad := get_dir_keypad() if strings.compare(type, "dirs") == 0 else get_number_keypad()
    defer delete(keypad)

    button_map: [4*3]u8
    index :: proc(pos: Vec) -> int { return pos.y * 3 + pos.x }
    
    for char, pos in keypad {
        button_map[index(pos)] = char
    }
    
    pos := keypad['A']
    for char in transmute([]u8)input {
        switch char {
        case '<': pos += LEFT
        case '>': pos += RIGHT
        case '^': pos += UP
        case 'v': pos += DOWN
        case 'A': fmt.printf("%c", button_map[index(pos)])
        }
        if button_map[index(pos)] == 'x' do panic("")
    }
    
    fmt.println()
}

execute :: proc(input: string) -> int {
    number_keypad := get_number_keypad()
    defer delete(number_keypad)
    
    dir_keypad := get_dir_keypad()
    defer delete(dir_keypad)
    
    complexity_sum := 0

    line_it := input
    for number_code in strings.split_lines_iterator(&line_it) {
        keypads := []map[u8]Vec { number_keypad, dir_keypad, dir_keypad }
        min_innermost_sequence_len := find_optimal_sequence(number_code, keypads)
        
        code_digits: [dynamic]u8
        defer delete(code_digits)
        for char in transmute([]u8)number_code {
            switch char {
            case '0'..='9': append(&code_digits, char)
            }
        }
        
        code_number := strconv.atoi(transmute(string)code_digits[:])
        complexity_sum += min_innermost_sequence_len * code_number
    }
    
    return complexity_sum
}

find_optimal_sequence :: proc(desired_sequence: string, keypads: []map[u8]Vec) -> int {
    keypad := keypads[0]
    pos := keypad['A']
    forbidden_pos := keypad['x']
    
    min_sequence_len_sum := 0

    for char in transmute([]u8)desired_sequence {
        char_pos := keypad[char]
        defer pos = char_pos
        pos_diff := char_pos - pos
        
        x_steps: [dynamic]u8
        defer delete(x_steps)
        for _ in 0..<abs(pos_diff.x) {
            if pos_diff.x < 0 do append(&x_steps, '<')
            else if pos_diff.x > 0 do append(&x_steps, '>')
        }
        
        y_steps: [dynamic]u8
        defer delete(y_steps)
        for _ in 0..<abs(pos_diff.y) {
            if pos_diff.y < 0 do append(&y_steps, '^')
            else if pos_diff.y > 0 do append(&y_steps, 'v')
        }
        
        sequences: [2][dynamic]u8
        defer for s in sequences do delete(s)
        
        if len(x_steps) > 0 && (pos.y != forbidden_pos.y || char_pos.x != forbidden_pos.x) {
            append(&sequences[0], ..x_steps[:])
            append(&sequences[0], ..y_steps[:])
            append(&sequences[0], 'A')
        }
        
        if len(y_steps) > 0 && (pos.x != forbidden_pos.x || char_pos.y != forbidden_pos.y) {
            append(&sequences[1], ..y_steps[:])
            append(&sequences[1], ..x_steps[:])
            append(&sequences[1], 'A')
        }
        
        if len(x_steps) == 0 && len(y_steps) == 0 do append(&sequences[0], 'A')
        
        min_innermost_sequence_len := max(int)
        for sequence in sequences {
            if len(sequence) == 0 do continue
        
            if len(keypads) > 1 {
                innermost_sequence_len := find_optimal_sequence(transmute(string)sequence[:], keypads[1:])
                min_innermost_sequence_len = min(innermost_sequence_len, min_innermost_sequence_len)
            } else {
                min_innermost_sequence_len = min(len(sequence), min_innermost_sequence_len)
            }
        }
        
        assert(min_innermost_sequence_len < max(int))
        min_sequence_len_sum += min_innermost_sequence_len
    }
    
    return min_sequence_len_sum
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
    
    if len(os.args) > 1 {
        simulate(os.args[1], os.args[2])
        return
    }
    
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
