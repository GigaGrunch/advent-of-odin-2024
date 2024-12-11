package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day11_test.txt", 55312 },
    { "day11_input.txt", nil },
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
        result := execute(input)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result do error_count += 1
        }
        fmt.println()
    }
}

execute :: proc{execute_bytes, execute_string}

execute_bytes :: proc(input: []u8) -> int {
    return execute_string(transmute(string)input)
}

execute_string :: proc(input: string) -> int {
    numbers: [dynamic]string
    defer delete(numbers)
    
    initial_numbers := strings.split(input, " ")
    defer delete(initial_numbers)
    
    for number in initial_numbers {
        trimmed := strings.trim_space(number)
        if len(trimmed) > 0 do append(&numbers, trimmed)
    }
    
    str_buffer: [dynamic]u8
    defer delete(str_buffer)
    
    fmt.println(numbers)
    
    for _ in 0..<25 {
        for i := len(numbers) - 1; i >= 0; i -= 1 {
            number_str := numbers[i]
            assert(len(number_str) > 0)
            
            for char in number_str do assert(is_digit(char))
            
            if all_zeros(number_str) {
                numbers[i] = "1"
            }
            else if is_even(len(number_str)) {
                number_1 := number_str[:len(number_str) / 2]
                number_2 := number_str[len(number_str) / 2:]
                numbers[i] = number_1
                inject_at(&numbers, i + 1, number_2)
            }
            else {
                number := strconv.atoi(number_str)
                number *= 2024
                buffer_start := len(str_buffer)
                for _ in 0..<digit_count(number) do append(&str_buffer, 0)
                numbers[i] = strconv.itoa(str_buffer[buffer_start:], number)
            }
        }
        
        fmt.println(numbers)
    }

    return len(numbers)
}

is_digit :: proc(char: rune) -> bool {
    switch char {
        case '0'..='9': return true
        case: return false
    }
}

all_zeros :: proc(str: string) -> bool {
    for char in str {
        if char != '0' do return false
    }
    return true
}

digit_count :: proc(number: int) -> int {
    remainder := number
    digits := 0
    for ;remainder > 0; remainder /= 10 {
        digits += 1
    }
    return digits
}

is_even :: proc(number: int) -> bool {
    return number % 2 == 0
}

print_progress :: proc(progress: f32) {
    fmt.printf("  %v%%  \r", int(progress * 100))
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
