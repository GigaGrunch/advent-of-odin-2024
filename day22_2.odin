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
    MAX_BUYER_COUNT :: 2000
    SECRET_NUMBER_COUNT :: 2001

    secret_numbers := make([][MAX_BUYER_COUNT]int, SECRET_NUMBER_COUNT)
    defer delete(secret_numbers)
    last_digits := make([][SECRET_NUMBER_COUNT]i8, MAX_BUYER_COUNT)
    defer delete(last_digits)
    last_digit_diffs := make([][SECRET_NUMBER_COUNT]i8, MAX_BUYER_COUNT)
    defer delete(last_digit_diffs)

    buyer_count := 0
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        secret_numbers[0][buyer_count] = strconv.atoi(line)
        buyer_count += 1
    }
    
    for i in 1..<SECRET_NUMBER_COUNT {
        secret_numbers[i] = ((secret_numbers[i-1] * 64) ~ secret_numbers[i-1]) % 16777216
        secret_numbers[i] = ((secret_numbers[i] / 32) ~ secret_numbers[i]) % 16777216
        secret_numbers[i] = ((secret_numbers[i] * 2048) ~ secret_numbers[i]) % 16777216
    }
    
    for buyer_i in 0..<buyer_count {
        for digit_i in 0..<SECRET_NUMBER_COUNT {
            last_digits[buyer_i][digit_i] = i8(secret_numbers[digit_i][buyer_i] % 10)
        }
        for digit_i in 1..<SECRET_NUMBER_COUNT {
            last_digit_diffs[buyer_i][digit_i] = last_digits[buyer_i][digit_i] - last_digits[buyer_i][digit_i-1]
        }
    }
    
    sequence_maps := make([]map[[4]i8]i8, buyer_count)
    defer {
        for m in sequence_maps do delete(m)
        delete(sequence_maps)
    }
    
    for buyer_i in 0..<buyer_count {
        for step in 1..<SECRET_NUMBER_COUNT - 3 {
            sequence := [4]i8 {
                last_digit_diffs[buyer_i][step],
                last_digit_diffs[buyer_i][step+1],
                last_digit_diffs[buyer_i][step+2],
                last_digit_diffs[buyer_i][step+3],
            }
            if sequence not_in sequence_maps[buyer_i] {
                sequence_maps[buyer_i][sequence] = last_digits[buyer_i][step+3]
            }
        }
    }
    
    sequence_index := 0
    sequence_count := 19 * 19 * 19 * 19
    
    max_payout := 0
    for s_0 in -9..=9 do for s_1 in -9..=9 do for s_2 in -9..=9 do for s_3 in -9..=9 {
        sequence := [4]i8 { i8(s_0), i8(s_1), i8(s_2), i8(s_3) }
        payout: [MAX_BUYER_COUNT]int
        
        defer sequence_index += 1
        fmt.printf("sequence %v/%v   \r", sequence_index+1, sequence_count)
        
        for buyer_i in 0..<buyer_count {
            payout[buyer_i] = int(sequence_maps[buyer_i][sequence])
        }
        
        payout_sum := math.sum(payout[:])
        if payout_sum > max_payout {
            max_payout = payout_sum
            fmt.printfln("sequence %v, payout: %v", sequence, payout_sum)
        }
    }
    
    return max_payout
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
