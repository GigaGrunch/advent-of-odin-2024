package main

import "core:fmt"
import "core:testing"
import "core:strconv"
import "core:math"
import "core:os"

main :: proc() {
    input_file := get_input_file()
    input := os.read_entire_file(input_file) or_else panic("Failed to read file.")
    result := execute(input)
    fmt.println(result)
}

@(test)
test :: proc(t: ^testing.T) {
    input := os.read_entire_file("day02_test.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 4)
}

execute :: proc(input: []u8) -> int {
    result := 0
    
    Dir :: enum{None, Inc, Dec}
    
    line_it := tokenize(input, {'\r', '\n'})
    for line in iterate(&line_it) {
        level_it := tokenize(line, {' '})
        
        level_count := 0
        for level in iterate_num(&level_it) {
            level_count += 1
        }
        
        for i in -1..<level_count {
            level_it.current = 0
        
            report_dir : Dir
            is_safe := true
            prev : Maybe(int)
            level_index := 0
        
            for level in iterate_num(&level_it) {
                defer level_index += 1
                if level_index == i do continue
                
                defer prev = level
                
                diff := 0
                dir := report_dir
                if prev != nil {
                    diff = level - prev.?
                    dir = .Inc if level > prev.? else .Dec
                }
                if report_dir == .None do report_dir = dir
                
                if dir != report_dir do is_safe = false
                if diff == 0 && report_dir != .None do is_safe = false
                if math.abs(diff) > 3 do is_safe = false
            }
            
            if is_safe {
                result += 1
                break
            }
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
