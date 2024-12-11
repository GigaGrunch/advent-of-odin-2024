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
        result := execute(transmute(string)input)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result do error_count += 1
        }
        fmt.println()
    }
}

execute :: proc(input: string) -> int {
    current := strings.builder_make()
    defer strings.builder_destroy(&current)
    
    next := strings.builder_make()
    defer strings.builder_destroy(&next)
    
    strings.write_string(&current, input)
    
    for _ in 0..<25 {
        current_str := transmute(string)current.buf[:]
    
        for number_str in strings.split_iterator(&current_str, " ") {
            if all_zeros(number_str) {
                strings.write_string(&next, "1 ")
            }
            else if is_even(len(number_str)) {
                number_1 := number_str[:len(number_str) / 2]
                number_2 := number_str[len(number_str) / 2:]
                strings.write_string(&next, number_1)
                strings.write_string(&next, " ")
                strings.write_string(&next, number_2)
                strings.write_string(&next, " ")
            }
            else {
                number := strconv.atoi(number_str)
                number *= 2024
                strings.write_int(&next, number)
                strings.write_string(&next, " ")
            }
        }
        
        strings.builder_reset(&current)
        strings.write_bytes(&current, next.buf[:])
        strings.builder_reset(&next)
    }
    
    count := 0
    final_str := transmute(string)current.buf[:]
    
    for _ in strings.split_iterator(&final_str, " ") {
        count += 1
    }

    return count
}

all_zeros :: proc(str: string) -> bool {
    for char in str {
        if char != '0' do return false
    }
    return true
}

is_even :: proc(number: int) -> bool {
    return number % 2 == 0
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
