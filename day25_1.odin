package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day25_test.txt", 3 },
    { "day25_input.txt", nil },
}

Key :: []int
Lock :: []int

execute :: proc(input: string) -> int {
    keys: [dynamic]Key
    locks: [dynamic]Lock
    defer {
        for key in keys do delete(key)
        delete(keys)
        for lock in locks do delete(lock)
        delete(locks)
    }
    
    width, height: int

    input_it := input
    for block in strings.split_iterator(&input_it, "\n\n") {
        block_it := block
        block_height := 0
        for line in strings.split_iterator(&block_it, "\n") {
            if width == 0 do width = len(line)
            else do assert(len(line) == width)
            block_height += 1
        }
        
        if height == 0 do height = block_height
        else do assert(block_height == height)
        
        columns := make([]int, width)
        block_it = block
        is_key, is_lock: bool
        line_i := 0
        for line in strings.split_iterator(&block_it, "\n") {
            all_hash := true
            for i in 0..<width {
                if line[i] == '#' do columns[i] += 1
                else do all_hash = false
            }
            
            if all_hash && line_i == 0 do is_lock = true
            if all_hash && line_i == height - 1 do is_key = true
            line_i += 1
        }
        
        if is_key do append(&keys, columns)
        else if is_lock do append(&locks, columns)
        else do panic(block)
    }
    
    matches := 0
    for lock in locks {
        for key in keys {
            is_match := true
            for i in 0..<width {
                is_match &= lock[i] + key[i] <= height
            }
            if is_match do matches += 1
        }
    }
    
    return matches
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
