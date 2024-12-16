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
    return 0
}
