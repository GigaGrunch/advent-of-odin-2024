package main

import "core:fmt"
import "core:testing"
import "core:strconv"
import "core:math"
import "core:os"
import "core:mem"

main :: proc() {
    input_file := get_input_file()
    input := os.read_entire_file(input_file) or_else panic("Failed to read file.")
    result := execute(input)
    fmt.println(result)
}

@(test)
test_1 :: proc(t: ^testing.T) {
    input := os.read_entire_file("day04_test3.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 1)
}

@(test)
test_2 :: proc(t: ^testing.T) {
    input := os.read_entire_file("day04_test2.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 9)
}

execute :: proc(input: []u8) -> int {
    result := 0
    
    lines: [dynamic][]u8
    defer delete(lines)
    
    lines_it := tokenize(input, {'\r', '\n'})
    for line in iterate(&lines_it) {
        append(&lines, line)
    }

    height := len(lines)
    width := len(lines[0])
    
    for y in 0..<height {
        for x in 0..<width {
            is_match :: proc(lines: [][]u8, start_x, start_y, x_dir, y_dir: int) -> bool {
                height := len(lines)
                width := len(lines[0])
            
                chars :: []u8 {'M', 'A', 'S'}
                for char, i in chars {
                    x := start_x + i * x_dir
                    y := start_y + i * y_dir
                    if x < 0 || x >= width do return false
                    if y < 0 || y >= height do return false
                    if lines[y][x] != char do return false
                }
                
                return true
            }
        
            top_left_bottom_right := is_match(lines[:], x-1, y-1, 1, 1) || is_match(lines[:], x+1, y+1, -1, -1)
            top_right_bottom_left := is_match(lines[:], x+1, y-1, -1, 1) || is_match(lines[:], x-1, y+1, 1, -1)
            
            if top_left_bottom_right && top_right_bottom_left do result += 1
        }
    }

    return result
}

get_input_file :: proc() -> string {
    context.allocator = context.temp_allocator

    odin_file_path : string = #file
    path_it := tokenize(transmute([]u8)odin_file_path, {'/'})
    file_name : []u8
    for part in iterate(&path_it) {
        file_name = part
    }
    
    split_it := tokenize(file_name, {'_'})
    day := iterate(&split_it) or_else panic("No '_' in the file path?")
    suffix_str : string = "_input.txt"
    suffix := transmute([]u8)suffix_str
    
    result : [dynamic]u8
    append(&result, ..day)
    append(&result, ..suffix)
    
    return transmute(string)result[:]
}

tokenize :: proc(data: []u8, split_chars: []u8) -> Tokenizer {
    return Tokenizer {
        data = data,
        split_chars = split_chars,
    }
}

iterate_num :: proc(it: ^Tokenizer) -> (number: int, ok: bool) {
    token := iterate(it) or_return
    return strconv.atoi(transmute(string)token), true
}

iterate :: proc(it: ^Tokenizer) -> (token: []u8, ok: bool) {
    at_split_char :: proc(it: ^Tokenizer) -> bool {
        current := it.data[it.current]
        for char in it.split_chars {
            if current == char do return true
        }
        return false
    }
    
    for it.current < len(it.data) {
        if at_split_char(it) do it.current += 1
        else do break
    }
    
    start := it.current
    if it.current >= len(it.data) do return nil, false
    
    for it.current < len(it.data) {
        if at_split_char(it) do break
        else do it.current += 1
    }
    
    return it.data[start:it.current], true
}

Tokenizer :: struct {
    data: []u8,
    split_chars: []u8,
    current: int,
}
