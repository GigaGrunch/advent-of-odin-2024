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
    numbers: map[int]int
    defer delete(numbers)
    
    number_split := strings.split(input, " ")
    defer delete(number_split)
    
    for number_str in number_split {
        number := strconv.atoi(number_str)
        count := numbers[number]
        numbers[number] = count + 1
    }
    
    str_buf: [100]u8
    
    next_numbers: map[int]int
    defer delete(next_numbers)
    
    for iteration in 0..<total_iterations {
        defer {
            clear(&numbers)
            for number in next_numbers do numbers[number] = next_numbers[number]
            clear(&next_numbers)
        }
    
        for old_number, old_count in numbers {
            num_str := strconv.itoa(str_buf[:], old_number)
            new_nums := []int { -1, -1 }
            
            if old_number == 0 {
                new_nums[0] = 1
            }
            else if len(num_str) % 2 == 0 {
                new_nums[0] = strconv.atoi(num_str[:len(num_str) / 2])
                new_nums[1] = strconv.atoi(num_str[len(num_str) / 2:])
            }
            else {
                new_nums[0] = old_number * 2024
            }
            
            for num in new_nums {
                if num != -1 {
                    new_count := next_numbers[num]
                    next_numbers[num] = new_count + old_count
                }
            }
        }
        
        fmt.printf("  %v/%v  \r", iteration, total_iterations)
    }
    
    total_count := 0
    for number, count in numbers do total_count += count
    
    return total_count
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
