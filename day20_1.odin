package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"
import "core:time"

runners := []struct{file_path: string, least_saved_picoseconds: int, expected_result: Maybe(int)} {
    { "day20_test.txt", 1, 44 },
    { "day20_input.txt", 100, nil },
}

Vec :: [2]u8
DIRECTIONS :: []Vec {
    Vec{0, max(u8)},
    Vec{0, 1},
    Vec{max(u8), 0},
    Vec{1, 0},
}

profile: struct {
    total: u64,
    init: u64,
    select_candidate: u64,
    delete_key: u64,
    direction_loop: u64,
}

print_profile :: proc() {
    print_value :: proc(name: string, value: u64) {
        fmt.printfln("%s %d (%.0f %%)", name, value, 100.0 * cast(f32)value / cast(f32)profile.total)
    }

    print_value("total", profile.total)
    print_value("init", profile.init)
    print_value("select_candidate", profile.select_candidate)
    print_value("delete_key", profile.delete_key)
    print_value("direction_loop", profile.direction_loop)
}

execute :: proc(input: string, least_saved_picoseconds: int) -> int {
    field_map: [dynamic]u8
    defer delete(field_map)

    width, height: int
    start_pos, end_pos: Vec

    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        y := height
        for char, x in transmute([]u8)line {
            append(&field_map, char)

            pos := Vec{u8(x), u8(y)}
            switch char {
            case 'S': start_pos = pos
            case 'E': end_pos = pos
            }
        }

        if width == 0 do width = len(line)
        else do assert(len(line) == width)
        height += 1
    }

    frontier := make(map[Vec]struct{})
    defer delete(frontier)
    path_lengths := make([]int, width * height)
    defer delete(path_lengths)
    guess_lengths := make([]int, width * height)
    defer delete(guess_lengths)

    initial_shortest_path := shortest_path_length(field_map[:], width, height, start_pos, end_pos, &frontier, path_lengths, guess_lengths)
    much_shorter_paths := 0

    for y in 0..<height {
        for x in 0..<width {
            pos := Vec{u8(x), u8(y)}
            char := at_ptr(field_map[:], width, height, pos)
            if char^ != '#' do continue

            char^ = '.'
            defer char^ = '#'

            shortest_path := shortest_path_length(field_map[:], width, height, start_pos, end_pos, &frontier, path_lengths, guess_lengths)
            if shortest_path <= initial_shortest_path - least_saved_picoseconds do much_shorter_paths += 1
        }
    }

    print_profile()

    return much_shorter_paths
}

shortest_path_length :: proc(field_map: []u8, width, height: int, start_pos, end_pos: Vec, frontier: ^map[Vec]struct{}, path_lengths, guess_lengths: []int) -> int {
    profile.total -= time.read_cycle_counter()
    defer profile.total += time.read_cycle_counter()

    profile.init -= time.read_cycle_counter()

    clear(frontier)
    frontier[start_pos] = {}

    slice.fill(path_lengths, max(int))
    at_ptr(path_lengths, width, height, start_pos)^ = 0

    slice.fill(guess_lengths, max(int))
    at_ptr(guess_lengths, width, height, start_pos)^ = get_direct_distance(start_pos, end_pos)

    profile.init += time.read_cycle_counter()

    for len(frontier) > 0 {
        profile.select_candidate -= time.read_cycle_counter()

        guess_length := max(int)
        pos: Vec
        for frontier_pos in frontier {
            length := at(guess_lengths, width, height, frontier_pos)
            if length < guess_length {
                guess_length = length
                pos = frontier_pos
            }
        }

        profile.select_candidate += time.read_cycle_counter()

        path_length := at(path_lengths, width, height, pos)
        if pos == end_pos do return path_length

        profile.delete_key -= time.read_cycle_counter()
        delete_key(frontier, pos)
        profile.delete_key += time.read_cycle_counter()

        profile.direction_loop -= time.read_cycle_counter()

        for direction in DIRECTIONS {
            neighbor := pos + direction
            if out_of_bounds(neighbor, width, height) do continue
            if at(field_map, width, height, neighbor) == '#' do continue

            neighbor_path_length := at_ptr(path_lengths, width, height, neighbor)
            tentative_path_length := path_length + 1
            if tentative_path_length >= neighbor_path_length^ do continue

            neighbor_path_length^ = tentative_path_length
            neighbor_guess_length := at_ptr(guess_lengths, width, height, neighbor)
            neighbor_guess_length^ = tentative_path_length + get_direct_distance(neighbor, end_pos)
            frontier[neighbor] = {}
        }

        profile.direction_loop += time.read_cycle_counter()
    }

    return max(int)
}

out_of_bounds :: proc(pos: Vec, width, height: int) -> bool {
    return pos.x >= u8(width) || pos.y >= u8(height)
}

get_direct_distance :: proc(lhs, rhs: Vec) -> int {
    return int(abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y))
}

at :: proc(list: []$T, width, height: int, pos: Vec) -> T {
    return list[to_index(width, height, pos)]
}

at_ptr :: proc(list: []$T, width, height: int, pos: Vec, loc := #caller_location) -> ^T {
    return &list[to_index(width, height, pos)]
}

to_index :: proc(width, height: int, pos: Vec) -> int {
    return int(pos.y) * width + int(pos.x)
}

print_map ::proc(field_map: []u8, width, height: int) {
    for char, i in field_map {
        fmt.printf("%c", char)
        if (i + 1) % width == 0 do fmt.println()
    }
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
        result := execute(transmute(string)input, runner.least_saved_picoseconds)

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
