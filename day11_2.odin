package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, iterations: int, expected_result: Maybe(int)} {
    { "day11_test.txt", 25, 55312 },
    { "day11_input.txt", 25, 199986 },
    { "day11_input.txt", 75, nil },
}

main :: proc() {
    error_count := 0
    defer {
        fmt.printfln("error count: %v", error_count)
        os.exit(error_count)
    }

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer deinit_tracking_allocator(&track)
    
    for runner in runners {
        input, file_ok := os.read_entire_file(runner.file_path)
        defer delete(input)
        if !file_ok {
            fmt.printfln("Failed to read file '%v'", runner.file_path)
            error_count += 1
            continue
        }
        result := execute(transmute(string)input, runner.iterations)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result do error_count += 1
        }
        fmt.println()
    }
}

execute :: proc(input: string, total_iterations: int) -> int {
    numbers: [dynamic]int
    defer delete(numbers)
    
    _input := input
    for number_str in strings.split_iterator(&_input, " ") {
        append(&numbers, strconv.atoi(number_str))
    }
    
    str_buf: [100]u8
    
    for iteration in 0..<total_iterations {
        for i := len(numbers) - 1; i >= 0; i -= 1 {
            number := numbers[i]
            num_str := strconv.itoa(str_buf[:], number)
            
            if number == 0 {
                numbers[i] = 1
            }
            else if len(num_str) % 2 == 0 {
                numbers[i] = strconv.atoi(num_str[:len(num_str) / 2])
                append(&numbers, strconv.atoi(num_str[len(num_str) / 2:]))
            }
            else {
                numbers[i] *= 2024
            }
        }
        
        fmt.printf("  %v/%v  \r", iteration, total_iterations)
    }
    
    return len(numbers)
}

deinit_tracking_allocator :: proc(track: ^mem.Tracking_Allocator) {
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
    mem.tracking_allocator_destroy(track)
}
