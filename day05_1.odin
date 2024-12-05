package main

import "core:fmt"
import "core:testing"
import "core:strconv"
import "core:math"
import "core:os"
import "core:mem"
import "core:strings"

main :: proc() {
    input_file := get_input_file()
    input := os.read_entire_file(input_file) or_else panic("Failed to read file.")
    result := execute(input)
    fmt.println(result)
}

@(test)
test_1 :: proc(t: ^testing.T) {
    input := `
M.S
.A.
M.S`
    result := execute(transmute([]u8)input)
    testing.expect_value(t, result, 1)
}

@(test)
test_2 :: proc(t: ^testing.T) {
    input := `
47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47`
    result := execute(transmute([]u8)input)
    testing.expect_value(t, result, 143)
}

execute :: proc(input: []u8) -> int {
    result := 0
    
    Rule :: struct{ lhs: int, rhs: int }
    rules: [dynamic]Rule
    defer delete(rules)
    
    lines_it := tokenize(input, "\r\n")
    for line in next_token(&lines_it) {
        rule_split := strings.split(line, "|", allocator=context.temp_allocator)
        if len(rule_split) != 2 do break
        
        append(&rules, Rule {
            lhs = strconv.atoi(rule_split[0]),
            rhs = strconv.atoi(rule_split[1]),
        })
    }
    
    fmt.printfln("rules: %v", rules)

    return result
}

get_input_file :: proc() -> string {
    context.allocator = context.temp_allocator

    odin_file_path: string = #file
    path_split := strings.split(odin_file_path, "/")
    file_name := path_split[len(path_split) - 1]
    
    file_name_split := strings.split(file_name, "_")
    
    day := file_name_split[0]
    suffix :: "_input.txt"
    
    builder := strings.builder_make()
    strings.write_string(&builder, day)
    strings.write_string(&builder, suffix)
    
    return transmute(string)builder.buf[:]
}

tokenize :: proc{tokenize_bytes, tokenize_string}

tokenize_string :: proc(data: string, split_chars: string) -> Tokenizer {
    return Tokenizer {
        data = transmute([]u8)data,
        split_chars = transmute([]u8)split_chars,
    }
}

tokenize_bytes :: proc(data: []u8, split_chars: string) -> Tokenizer {
    return Tokenizer {
        data = data,
        split_chars = transmute([]u8)split_chars,
    }
}

next_token :: proc(it: ^Tokenizer) -> (string, bool) {
    token, _, ok := next_token_indexed(it)
    return token, ok
}

next_token_indexed :: proc(it: ^Tokenizer) -> (string, int, bool) {
    at_split_char :: proc(it: ^Tokenizer) -> bool {
        for char in it.split_chars {
            if char == it.data[it.current] do return true
        }
        return false
    }
    
    for it.current < len(it.data) {
        if at_split_char(it) do it.current += 1
        else do break
    }
    
    if it.current == len(it.data) do return "", 0, false
    start := it.current
    
    for it.current < len(it.data) {
        if at_split_char(it) do break
        else do it.current += 1
    }
    
    result := it.data[start:it.current]
    result_str := transmute(string)result
    trimmed_result := strings.trim_space(result_str)
    
    defer it.token_index += 1
    return trimmed_result, it.token_index, true
}

Tokenizer :: struct {
    data: []u8,
    split_chars: []u8,
    current: int,
    token_index: int,
}
