package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day22_test2.txt", 23 },
    { "day22_input.txt", nil },
}

execute :: proc(input: string) -> int {
    secret_numbers := make([][2000]int, 2001)
    defer delete(secret_numbers)

    index := 0
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        secret_numbers[0][index] = strconv.atoi(line)
        index += 1
    }
    
    for i in 1..=2000 {
        secret_numbers[i] = ((secret_numbers[i-1] * 64) ~ secret_numbers[i-1]) % 16777216
        secret_numbers[i] = ((secret_numbers[i] / 32) ~ secret_numbers[i]) % 16777216
        secret_numbers[i] = ((secret_numbers[i] * 2048) ~ secret_numbers[i]) % 16777216
    }
    
    return math.sum(secret_numbers[2000][:])
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
        defer fmt.println()
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if expected_result != result {
                error_count += 1
                break
            }
        }
    }
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
