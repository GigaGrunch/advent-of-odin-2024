package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day23_test.txt", 7 },
    { "day23_input.txt", nil },
}

void :: struct{}
Name :: [2]u8

execute :: proc(input: string) -> int {
    names_connections: map[Name]map[Name]void
    defer {
        for _, connections in names_connections do delete(connections)
        delete(names_connections)
    }

    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        name_it := line
        lhs := strings.split_iterator(&name_it, "-") or_else panic(line)
        rhs := strings.split_iterator(&name_it, "-") or_else panic(line)
        assert(len(lhs) == 2)
        assert(len(rhs) == 2)
        lhs_name := Name{lhs[0], lhs[1]}
        rhs_name := Name{rhs[0], rhs[1]}
        if lhs_name not_in names_connections do names_connections[lhs_name] = {}
        if rhs_name not_in names_connections do names_connections[rhs_name] = {}
        lhs_map := &names_connections[lhs_name]
        lhs_map[rhs_name] = {}
        rhs_map := &names_connections[rhs_name]
        rhs_map[lhs_name] = {}
    }
    
    sets_of_three: map[[3]Name]void
    defer delete(sets_of_three)
    
    for computer_a, a_connections in names_connections {
        for computer_b in a_connections {
            if computer_b == computer_a do continue
            for computer_c in a_connections {
                if computer_c == computer_a do continue
                if computer_c == computer_b do continue
                if computer_c in names_connections[computer_b] {
                    set_of_three := [3]Name {computer_a, computer_b, computer_c}
                    slice.sort_by(set_of_three[:], proc(lhs, rhs: Name) -> bool {
                        if lhs[0] == rhs[0] do return lhs[1] < rhs[1]
                        return lhs[0] < rhs[0]
                    })
                    sets_of_three[set_of_three] = {}
                }
            }
        }
    }
    
    chief_candidate_count := 0
    
    for set in sets_of_three {
        if set[0][0] == 't' || set[1][0] == 't' || set[2][0] == 't' {
            chief_candidate_count += 1
        }
    }
    
    return chief_candidate_count
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
