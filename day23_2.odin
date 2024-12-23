package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, expected_result: Maybe(string)} {
    { "day23_test.txt", "co,de,ka,ta" },
    { "day23_input.txt", nil },
}

void :: struct{}
Name :: [2]u8
name_order :: proc(lhs, rhs: Name) -> bool {
    if lhs[0] == rhs[0] do return lhs[1] < rhs[1]
    return lhs[0] < rhs[0]
}

execute :: proc(input: string) -> string {
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
    
    parties: [dynamic]map[Name]void
    defer {
        for party in parties do delete(party)
        delete(parties)
    }
    
    for computer_a, a_connections in names_connections {
        has_any_party := false
        for party in parties do if computer_a in party do has_any_party = true
        
        if !has_any_party {
            new_index := len(parties)
            append(&parties, map[Name]void{})
            new_party := &parties[new_index]
            new_party[computer_a] = {}
        }
    
        for &party in parties {
            if computer_a in party {
                outer: for computer_b in a_connections {
                    if computer_b == computer_a do continue
                    if computer_b in party do continue
                    for party_computer in party {
                        if party_computer not_in names_connections[computer_b] {
                            continue outer
                        }
                    }
                    party[computer_b] = {}
                }
            }
        }
    }
    
    biggest_party: ^map[Name]void
    biggest_party_size := 0
    
    for &party in parties {
        if len(party) > biggest_party_size {
            biggest_party = &party
            biggest_party_size = len(party)
        }
    }
    
    sorted_biggest_party: [dynamic]Name
    defer delete(sorted_biggest_party)
    
    for computer in biggest_party do append(&sorted_biggest_party, computer)
    slice.sort_by(sorted_biggest_party[:], name_order)
    
    computer_names: [dynamic]string
    defer {
        for name in computer_names do delete(name)
        delete(computer_names)
    }
    
    for computer in sorted_biggest_party {
        append(&computer_names, fmt.aprintf("%s", computer))
    }
    
    return strings.join(computer_names[:], ",")
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
        defer delete(result)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        defer fmt.println()
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if strings.compare(result, expected_result) != 0 {
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
