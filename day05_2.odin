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
test :: proc(t: ^testing.T) {
    input := os.read_entire_file("day05_test.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 123)
}

execute :: proc(input: []u8) -> int {
    result := 0
    
    Rule :: struct{ lhs: int, rhs: int }
    rules: [dynamic]Rule
    defer delete(rules)
    
    lines_it := tokenize(input, "\r\n")
    for line in next_token(&lines_it) {
        defer free_all(context.temp_allocator)
    
        rule_split := strings.split(line, "|", allocator=context.temp_allocator)
        if len(rule_split) == 2 {
            append(&rules, Rule {
                lhs = strconv.atoi(rule_split[0]),
                rhs = strconv.atoi(rule_split[1]),
            })
        }
        else {
            number_split := strings.split(line, ",", allocator=context.temp_allocator)
            all_numbers := make([dynamic]int, allocator=context.temp_allocator)
            for str in number_split {
                append(&all_numbers, strconv.atoi(str))
            }
            
            applicable_rules := make([dynamic]Rule, allocator=context.temp_allocator)
            is_applicable :: proc(numbers: []int, rule: Rule) -> bool {
                lhs_found := false
                rhs_found := false
                for number in numbers {
                    if rule.lhs == number do lhs_found = true
                    if rule.rhs == number do rhs_found = true
                    if lhs_found && rhs_found do return true
                }
                return false
            }
            for rule in rules {
                if is_applicable(all_numbers[:], rule) {
                    append(&applicable_rules, rule)
                }
            }
            
            printed_numbers := make([dynamic]int, allocator=context.temp_allocator)
            is_printed :: proc(printed_numbers: []int, number: int) -> bool {
                for other in printed_numbers do if other == number do return true
                return false
            }
            
            can_be_printed :: proc(rules: []Rule, printed_numbers: []int, number: int) -> bool {
                for rule in rules {
                    if number == rule.rhs && !is_printed(printed_numbers, rule.lhs) {
                        return false
                    }
                }
                return true
            }
            
            is_correct_order := true
            for number in all_numbers {
                if !can_be_printed(applicable_rules[:], printed_numbers[:], number) {
                    is_correct_order = false
                    break
                }
                append(&printed_numbers, number)
            }
            if is_correct_order do continue
            
            clear(&printed_numbers)
            
            next_all_numbers := make([dynamic]int, allocator=context.temp_allocator)
            
            for len(all_numbers) > 0 {
                defer {
                    clear(&all_numbers)
                    append(&all_numbers, ..next_all_numbers[:])
                    clear(&next_all_numbers)
                }
                
                for number in all_numbers {
                    if can_be_printed(applicable_rules[:], printed_numbers[:], number) {
                        append(&printed_numbers, number)
                    }
                    else {
                        append(&next_all_numbers, number)
                    }
                }
            }
            
            middle_index := len(printed_numbers) / 2
            result += printed_numbers[middle_index]
        }
    }

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
