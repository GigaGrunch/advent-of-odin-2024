package main

import "core:fmt"
import "core:testing"

main :: proc() {
    fmt.println("Hello Sailor!")
}

@(test)
test :: proc(t: ^testing.T) {
    input := "3   4\n4   3\n2   5\n1   3\n3   9\n3   3\n"
    result := execute(transmute([]u8)input)
    testing.expect_value(t, result, 11)
}

execute :: proc(input: []u8) -> int {
    return 0
}
