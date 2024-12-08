package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }

    test_input := `
190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20
`
    test_result := execute(test_input)
    fmt.printfln("Test input -> %v (expected 3749)", test_result)
    
    file_path :: "day07_input.txt"
    input, file_ok := os.read_entire_file(file_path)
    defer delete(input)
    if !file_ok {
        fmt.printfln("Failed to read file '%v'", file_path)
        os.exit(1)
    }
    result := execute(transmute(string)input)
    fmt.printfln("Real input -> %v", result)
}

execute :: proc(input: string) -> int {
    result := 0
    
    lines := strings.split_lines(input)
    defer delete(lines)
    for line in lines {
        if len(line) == 0 do continue
        
        result_args_split := strings.split(line, ": ")
        defer delete(result_args_split)
        assert(len(result_args_split) == 2, line)
        
        result := strconv.atoi(result_args_split[0])
        
        args := strings.split(result_args_split[1], " ")
        defer delete(args)
        
        op_count := uint(len(args) - 1)
        combination_count := uint(1 << op_count)
        
        for combination_index in 0..<combination_count {
            fmt.printf("combination %v: ", combination_index)
            for op in 0..<op_count {
                op_mask: uint = 1 << op
                is_mul := combination_index & op_mask == op_mask
                fmt.printf("%v ", "*" if is_mul else "+")
            }
            fmt.println()
        }
    }

    return result
}
