package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:os"
import "core:testing"
import "core:slice"

runners := []struct{file_path: string, map_dimensions: [2]int, expected_result: Maybe(int)} {
    { "day14_test.txt", [2]int { 11, 7 }, 12 },
    { "day14_input.txt", [2]int { 101, 103 }, nil },
}

ARRAY_LENGTH :: 500

execute :: proc(input: string, map_dimensions: [2]int) -> int {
    bot_count := 0
    positions: [2][ARRAY_LENGTH]int
    velocities: [2][ARRAY_LENGTH]int
    
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        value_it := line
        for value_str in strings.split_iterator(&value_it, " ") {
            xy_it := value_str[2:]
            x_str := strings.split_iterator(&xy_it, ",") or_else panic(line)
            y_str := strings.split_iterator(&xy_it, ",") or_else panic(line)
            x := strconv.atoi(x_str)
            y := strconv.atoi(y_str)
            switch value_str[0] {
            case 'p':
                positions.x[bot_count] = x
                positions.y[bot_count] = y
            case 'v':
                velocities.x[bot_count] = x
                velocities.y[bot_count] = y
            case: panic(line)
            }
        }
    
        bot_count += 1
    }
    
    positions += velocities * 100
    
    min_pos := [2]int { slice.min(positions.x[:]), slice.min(positions.y[:]) }
    make_positive := map_dimensions + map_dimensions * (-min_pos / map_dimensions)
    make_positive_array: [2][ARRAY_LENGTH]int
    slice.fill(make_positive_array.x[:], make_positive.x)
    slice.fill(make_positive_array.y[:], make_positive.y)
    positions += make_positive_array
    
    map_dimensions_array: [2][ARRAY_LENGTH]int
    slice.fill(map_dimensions_array.x[:], map_dimensions.x)
    slice.fill(map_dimensions_array.y[:], map_dimensions.y)
    positions %= map_dimensions_array
    
    top_left_bots, top_right_bots, bottom_left_bots, bottom_right_bots: int
    
    middle_pos := map_dimensions / 2
    
    for i in 0..<bot_count {
        pos := [2]int { positions.x[i], positions.y[i] }
    
        switch {
        case pos.x < middle_pos.x && pos.y < middle_pos.y: top_left_bots += 1
        case pos.x > middle_pos.x && pos.y < middle_pos.y: top_right_bots += 1
        case pos.x < middle_pos.x && pos.y > middle_pos.y: bottom_left_bots += 1
        case pos.x > middle_pos.x && pos.y > middle_pos.y: bottom_right_bots += 1
        }
    }

    return top_left_bots * top_right_bots * bottom_left_bots * bottom_right_bots
}

print :: proc(positions: [2][ARRAY_LENGTH]int, len: int) {
    for i in 0..<len {
        fmt.printf("(%v,%v) ", positions.x[i], positions.y[i])
    }
    fmt.println()
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
        result := execute(transmute(string)input, runner.map_dimensions)
        
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
