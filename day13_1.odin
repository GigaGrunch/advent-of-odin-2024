package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day13_test.txt", 480 },
    { "day13_input.txt", nil },
}

execute :: proc(input: string) -> int {
    total_cost := 0

    input_it_str := input
    for block in strings.split_iterator(&input_it_str, "\n\n") {
        button_a: [2]int
        button_b: [2]int
        prize: [2]int
    
        block_it_str := block
        for line in strings.split_lines_iterator(&block_it_str) {
            line_it_str := line
            id := strings.split_iterator(&line_it_str, ": ") or_else panic(line)
            
            parse_value :: proc(it_str: ^string, id_char: u8, line: string) -> int {
                value_str := strings.split_iterator(it_str, ", ") or_else panic(line)
                assert(value_str[0] == id_char)
                return strconv.atoi(value_str[2:])
            }
            
            value := [2]int {
                parse_value(&line_it_str, 'X', line),
                parse_value(&line_it_str, 'Y', line),
            }
            
            if strings.compare(id, "Button A") == 0 do button_a = value
            else if strings.compare(id, "Button B") == 0 do button_b = value
            else if strings.compare(id, "Prize") == 0 do prize = value
            else do panic(line)
        }
        
        calculate_count :: proc(button, other_button, prize: [2]int) -> (count: int, other_count: int) {
            count = 0
            remaining_prize := prize
            for remaining_prize % other_button != 0 {
                remaining_prize -= button
                count += 1
                if count > 100 do return 0, 0
            }
            other_count = (remaining_prize / other_button)[0]
            if other_count > 100 do return 0, 0
            return
        }
        
        a_first_cost := 0
        {
            a_count, b_count := calculate_count(button_a, button_b, prize)
            a_first_cost = a_count * 3 + b_count
        }
        b_first_cost := 0
        {
            b_count, a_count := calculate_count(button_b, button_a, prize)
            b_first_cost = a_count * 3 + b_count
        }
        
        if a_first_cost == 0 do total_cost += b_first_cost
        else if b_first_cost == 0 do total_cost += a_first_cost
        else do total_cost += min(a_first_cost, b_first_cost)
    }

    return total_cost
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
