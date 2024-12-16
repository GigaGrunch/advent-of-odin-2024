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
    input := os.read_entire_file("day03_test2.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(transmute([]u8)input)
    testing.expect_value(t, result, 48)
}

execute :: proc(input: []u8) -> int {
    result := 0

    min_expr :: "mul(x,x)"
    min_expr_len :: len(min_expr)
    
    mul_enabled := true
    
    outer_loop: for i := 0; i <= len(input)-min_expr_len; {
        do_ref :: []u8 {'d', 'o', '(', ')'}
        do_str := input[i:][:len(do_ref)]
        dont_ref :: []u8 {'d', 'o', 'n', '\'', 't', '(', ')'}
        dont_str := input[i:][:len(dont_ref)]
        mul_ref :: []u8 {'m', 'u', 'l'}
        mul_str := input[i:][:len(mul_ref)]
        
        if mem.compare(do_str, do_ref) == 0 {
            i += len(do_ref)
            mul_enabled = true
        }
        else if mem.compare(dont_str, dont_ref) == 0 {
            i += len(dont_ref)
            mul_enabled = false
        }
        else if mem.compare(mul_str, mul_ref) == 0 {
            i += len(mul_ref)
        
            if input[i] == '(' {
                i += 1
                
                num_1_start := i
                num_1_loop: for i < len(input) {
                    switch input[i] {
                        case '0'..='9': i += 1
                        case ',': break num_1_loop
                        case: continue outer_loop
                    }
                }
                num_1_end := i
                
                i += 1 // skip the ','
                
                num_2_start := i
                num_2_loop: for i < len(input) {
                    switch input[i] {
                        case '0'..='9': i += 1
                        case ')': break num_2_loop
                        case: continue outer_loop
                    }
                }
                num_2_end := i
                
                num_1_str := input[num_1_start:num_1_end]
                num_2_str := input[num_2_start:num_2_end]
                num_1 := strconv.atoi(transmute(string)num_1_str)
                num_2 := strconv.atoi(transmute(string)num_2_str)
                
                if mul_enabled do result += num_1 * num_2
            }
        }
        else {
            i += 1
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
