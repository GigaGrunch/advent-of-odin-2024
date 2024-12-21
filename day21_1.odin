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
        fmt.println("----------------------")
    
        keypads := []map[u8]Vec {
            number_keypad,
            dir_keypad,
            dir_keypad,
        }
        
        current_code, next_code: [dynamic]u8
        defer delete(current_code)
        defer delete(next_code)
        append(&current_code, ..transmute([]u8)number_code)
        
        for keypad in keypads {
            pos := keypad['A']
            forbidden_pos := keypad['x']
            
            clear(&next_code)
            
            fmt.print("\n")
            
            for char in current_code {
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
                    case UP: key_press = '^'
                    case DOWN: key_press = 'v'
                    case LEFT: key_press = '<'
                    case RIGHT: key_press = '>'
                    }
                    
                    for ;abs(diff) > 0; diff = char_pos[axis] - pos[axis] {
                        pos += dir
                        append(&next_code, key_press)
                        fmt.printf("%c\033[A\033[D \033[B", key_press)
                    }
                }
                
                append(&next_code, 'A')
                fmt.printf("A\033[A\033[D%c\033[B", char)
            }
            
            fmt.println()
            fmt.println()
            
            clear(&current_code)
            append(&current_code, ..next_code[:])
        }
        
        number_code_digits: [dynamic]u8
        defer delete(number_code_digits)
        
        for char in transmute([]u8)number_code {
            switch char {
            case '0'..='9': append(&number_code_digits, char)
            }
        }
        
        sequence_length := len(current_code)
        code_number := strconv.atoi(transmute(string)number_code_digits[:])
        
        product := sequence_length * code_number
        complexity_sum += product
        
        fmt.printfln("sequence length: %v, number: %v, %v * %v = %v", sequence_length, code_number, sequence_length, code_number, product)
    }
    
    return complexity_sum
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
