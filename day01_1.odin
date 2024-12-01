package main

import "core:fmt"
import "core:testing"
import "core:os"

main :: proc() {
    fmt.println("Hello Sailor!")
}

@(test)
test :: proc(t: ^testing.T) {
    input := os.read_entire_file("day01_test.txt") or_else panic("Failed to read test file.")
    defer delete(input)
    result := execute(input)
    testing.expect_value(t, result, 11)
}

execute :: proc(input: []u8) -> int {
    lines_it := tokenize(input, { '\r', '\n' })
    
    for line in iterate(&lines_it) {
        fmt.printfln("line: %v", line)
    }

    return 0
}

tokenize :: proc(data: []u8, split_chars: []u8) -> Tokenizer {
    return Tokenizer {
        data = data,
        split_chars = split_chars,
    }
}

iterate :: proc(it: ^Tokenizer) -> (token: Maybe([]u8), ok: bool) {
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
