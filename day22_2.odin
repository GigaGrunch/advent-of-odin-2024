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
    last_digits := make([][2000]int, 2001)
    defer delete(last_digits)
    last_digit_diffs := make([][2000]int, 2001)
    defer delete(last_digit_diffs)

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
        
        last_digits[i] = secret_numbers[i] % 10
        last_digit_diffs[i] = last_digits[i] - last_digits[i-1]
    }
    
    max_payout := 0
    for s_0 in -9..=9 do for s_1 in -9..=9 do for s_2 in -9..=9 do for s_3 in -9..=9 {
        sequence := []int { s_0, s_1, s_2, s_3 }
        payout: [2000]int
        
        outer: for buyer_i in 0..<index {
            for step in 0..<len(last_digit_diffs) - 3 {
                if last_digit_diffs[step][buyer_i] == sequence[0] &&
                        last_digit_diffs[step+1][buyer_i] == sequence[1] &&
                        last_digit_diffs[step+2][buyer_i] == sequence[2] &&
                        last_digit_diffs[step+3][buyer_i] == sequence[3] {
                    payout[buyer_i] = last_digits[step+3][buyer_i]
                    continue outer
                }
            }
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
