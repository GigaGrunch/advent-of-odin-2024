package main

import "core:fmt"
import "core:testing"
import "core:strconv"
import "core:math"
import "core:os"

main :: proc() {
    input, _ := os.read_entire_file("day01_input.txt")
    result := execute(input)
    fmt.println(result)
}

@(test)
test :: proc(t: ^testing.T) {
    input := os.read_entire_file("day01_test.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 11)
}

execute :: proc(input: []u8) -> int {
    left_numbers: [dynamic]int
    defer delete(left_numbers)
    right_numbers: [dynamic]int
    defer delete(right_numbers)

    lines_it := tokenize(input, { '\r', '\n' })
    for line in iterate(&lines_it) {
        numbers_it := tokenize(line, {' '})
        left_number, _ := iterate(&numbers_it)
        right_number, _ := iterate(&numbers_it)
        append(&left_numbers, strconv.atoi(string(left_number)))
        append(&right_numbers, strconv.atoi(string(right_number)))
    }
    
    sort :: proc(numbers: []int) {
        for _ in numbers {
            for i in 1..<len(numbers) {
                number := numbers[i - 1]
                other := numbers[i]
                if other < number {
                    numbers[i - 1] = other
                    numbers[i] = number
                }
            }
        }
    }
    
    sort(left_numbers[:])
    sort(right_numbers[:])
    
    result := 0
    
    for i in 0..<len(left_numbers) {
        result += math.abs(left_numbers[i] - right_numbers[i])
    }

    return result
}

tokenize :: proc(data: []u8, split_chars: []u8) -> Tokenizer {
    return Tokenizer {
        data = data,
        split_chars = split_chars,
    }
}

iterate :: proc(it: ^Tokenizer) -> (token: []u8, ok: bool) {
    if it.current >= len(it.data) do return nil, false
    
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
