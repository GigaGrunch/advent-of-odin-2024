package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, expected_result: Maybe(int)} {
    { "day24_test1.txt", 4 },
    { "day24_test2.txt", 2024 },
    { "day24_input.txt", nil },
}

Name :: [3]u8
Value :: u8
Op :: enum{and, or, xor}
Gate :: struct {
    op: Op,
    lhs, rhs: Name,
    out: Name,
}

name_from_string :: proc(str: string) -> Name {
    assert(len(str) == 3)
    return Name{str[0], str[1], str[2]}
}

name_order :: proc(lhs, rhs: Name) -> bool {
    for i in 0..<len(lhs) {
        if lhs[i] < rhs[i] do return true
        if lhs[i] > rhs[i] do return false
    }
    return false
}

value_from_string :: proc(str: string) -> Value {
    switch str {
    case "0": return 0
    case "1": return 1
    case: panic(str)
    }
}

op_from_string :: proc(str: string) -> Op {
    switch str {
    case "AND": return .and
    case "OR": return .or
    case "XOR": return .xor
    case: panic(str)
    }
}

execute :: proc(input: string) -> int {
    values: map[Name]Value
    defer delete(values)
    
    pending_gates: [dynamic]Gate
    defer delete(pending_gates)

    line_it := input
    
    for line in strings.split_lines_iterator(&line_it) {
        if len(line) == 0 do break
    
        split_it := line
        name := name_from_string(strings.split_iterator(&split_it, ": ") or_else panic(line))
        value := value_from_string(strings.split_iterator(&split_it, ": ") or_else panic(line))
        values[name] = value
    }
    
    for line in strings.split_lines_iterator(&line_it) {
        split_it := line
        from_str := strings.split_iterator(&split_it, " -> ") or_else panic(line)
        out := name_from_string(strings.split_iterator(&split_it, " -> ") or_else panic(line))
        from_split := from_str
        lhs := name_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        op := op_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        rhs := name_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        append(&pending_gates, Gate {
            op = op,
            lhs = lhs,
            rhs = rhs,
            out = out,
        })
    }
    
    pending_z_values := 1
    for pending_z_values > 0 {
        pending_z_values = 0
        
        for i := len(pending_gates) - 1; i >= 0; i -= 1 {
            gate := pending_gates[i]
            if gate.lhs not_in values || gate.rhs not_in values {
                if gate.out[0] == 'z' do pending_z_values += 1
                continue
            }
            assert(gate.out not_in values)
            defer unordered_remove(&pending_gates, i)
            switch gate.op {
            case .and: values[gate.out] = values[gate.lhs] & values[gate.rhs]
            case .or: values[gate.out] = values[gate.lhs] | values[gate.rhs]
            case .xor: values[gate.out] = values[gate.lhs] ~ values[gate.rhs]
            }
        }
    }
    
    sorted_z_names: [dynamic]Name
    defer delete(sorted_z_names)
    for name in values do if name[0] == 'z' do append(&sorted_z_names, name)
    slice.sort_by(sorted_z_names[:], name_order)
    
    sorted_z_values: [dynamic]u8
    defer delete(sorted_z_values)
    for name in sorted_z_names do append(&sorted_z_values, values[name])
    
    result := 0
    for val, i in sorted_z_values {
        if val == 1 do result += pot(i)
    }
    return result
}

pot :: proc(exp: int) -> int {
    result := 1
    for _ in 0..<exp do result *= 2
    return result
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
