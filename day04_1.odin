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
test :: proc(t: ^testing.T) {
    input := os.read_entire_file("day04_test1.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 4)
}

execute :: proc(input: []u8) -> int {
    result := 0
    
    lines: [dynamic][]u8
    defer delete(lines)
    
    lines_it := tokenize(input, {'\r', '\n'})
    for line in iterate(&lines_it) {
        append(&lines, line)
    }

    chars_after_x :: 3
    
    for line, y in lines {
        for _, x in line {
            is_match :: proc(lines: [][]u8, x, y, x_dir, y_dir: int) -> bool {
                height := len(lines)
                width := len(lines[0])
            
                chars :: []u8 {'X', 'M', 'A', 'S'}
                for char, i in chars {
                    _x := x + i * x_dir
                    _y := y + i * y_dir
                    if _x < 0 || _x >= width do return false
                    if _y < 0 || _y >= height do return false
                    if lines[_y][_x] != char do return false
                }
                
                return true
            }
            
            if is_match(lines[:], x, y, 1, 0) do result += 1
            if is_match(lines[:], x, y, -1, 0) do result += 1
            if is_match(lines[:], x, y, 0, 1) do result += 1
            if is_match(lines[:], x, y, 0, -1) do result += 1
            if is_match(lines[:], x, y, 1, 1) do result += 1
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
