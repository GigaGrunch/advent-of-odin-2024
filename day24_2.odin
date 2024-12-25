package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"

runners := []struct{file_path: string, swap_pairs: int, super_op: string, expected_result: Maybe(string)} {
    { "day24_test3.txt", 2, "&", "z00,z01,z02,z05" },
    { "day24_input.txt", 4, "+", nil },
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

execute :: proc(input: string, swap_pairs: int, super_op: string) -> string {
    initial_values: map[Name]Value
    defer delete(initial_values)
    
    all_gates: [dynamic]Gate
    defer delete(all_gates)
    
    sorted_x_names: [dynamic]Name
    defer delete(sorted_x_names)
    sorted_y_names: [dynamic]Name
    defer delete(sorted_y_names)
    sorted_z_names: [dynamic]Name
    defer delete(sorted_z_names)

    line_it := input
    
    for line in strings.split_lines_iterator(&line_it) {
        if len(line) == 0 do break
    
        split_it := line
        name := name_from_string(strings.split_iterator(&split_it, ": ") or_else panic(line))
        value := value_from_string(strings.split_iterator(&split_it, ": ") or_else panic(line))
        initial_values[name] = value
        
        switch name[0] {
        case 'x': append(&sorted_x_names, name)
        case 'y': append(&sorted_y_names, name)
        case 'z': append(&sorted_z_names, name)
        }
    }
    
    for line in strings.split_lines_iterator(&line_it) {
        split_it := line
        from_str := strings.split_iterator(&split_it, " -> ") or_else panic(line)
        out := name_from_string(strings.split_iterator(&split_it, " -> ") or_else panic(line))
        from_split := from_str
        lhs := name_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        op := op_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        rhs := name_from_string(strings.split_iterator(&from_split, " ") or_else panic(line))
        append(&all_gates, Gate {
            op = op,
            lhs = lhs,
            rhs = rhs,
            out = out,
        })
        
        switch out[0] {
        case 'x': append(&sorted_x_names, out)
        case 'y': append(&sorted_y_names, out)
        case 'z': append(&sorted_z_names, out)
        }
    }
    
    slice.sort_by(sorted_x_names[:], name_order)
    slice.sort_by(sorted_y_names[:], name_order)
    slice.sort_by(sorted_z_names[:], name_order)
    
    sorted_x_values := make([]u8, len(sorted_x_names))
    defer delete(sorted_x_values)
    sorted_y_values := make([]u8, len(sorted_y_names))
    defer delete(sorted_y_values)
    sorted_z_values := make([]u8, len(sorted_z_names))
    defer delete(sorted_z_values)
    
    swap_gates := make([]int, swap_pairs * 2)
    defer delete(swap_gates)
    
    for i in 0..<len(swap_gates) do swap_gates[i] = len(swap_gates) - i - 1
    
    outer: for {
        has_dupes := false
        for i in 0..<len(swap_gates) {
            for j in 0..<len(swap_gates) {
                if i != j && swap_gates[i] == swap_gates[j] {
                    has_dupes = true
                }
            }
        }
        
        if !has_dupes {
            fmt.printf("swap: %v ", swap_gates)
            defer fmt.println()
        
            pending_gates: [dynamic]Gate
            defer delete(pending_gates)
            for gate_i in 0..<len(all_gates) {
                gate := all_gates[gate_i]
                for swap_gate_i, swap_gate_i_i in swap_gates {
                    if gate_i == swap_gate_i {
                        swap_gate := all_gates[swap_gates[swap_gate_i_i+1]] if swap_gate_i_i % 2 == 0 else all_gates[swap_gates[swap_gate_i_i-1]]
                        fmt.printf("%s->%s ", gate.out, swap_gate.out)
                        gate.out = swap_gate.out
                    }
                }
                append(&pending_gates, gate)
            }
            
            values: map[Name]Value
            defer delete(values)
            for name, value in initial_values do values[name] = value
    
            pending_changed := true
            has_pending_xyz := true
            for pending_changed {
                pending_changed = false
                has_pending_xyz = false
                for pending_gate_i := len(pending_gates) - 1; pending_gate_i >= 0; pending_gate_i -= 1 {
                    gate := pending_gates[pending_gate_i]
                    if gate.lhs not_in values || gate.rhs not_in values {
                        switch gate.out[0] {
                        case 'x', 'y', 'z': has_pending_xyz = true
                        }
                        continue
                    }
                    assert(gate.out not_in values)
                    defer unordered_remove(&pending_gates, pending_gate_i)
                    pending_changed = true
                    switch gate.op {
                    case .and: values[gate.out] = values[gate.lhs] & values[gate.rhs]
                    case .or: values[gate.out] = values[gate.lhs] | values[gate.rhs]
                    case .xor: values[gate.out] = values[gate.lhs] ~ values[gate.rhs]
                    }
                }
            }
            
            if !has_pending_xyz {
                for name, i in sorted_x_names do sorted_x_values[i] = values[name]
                for name, i in sorted_y_names do sorted_y_values[i] = values[name]
                for name, i in sorted_z_names do sorted_z_values[i] = values[name]
                
                fmt.printf("z: %v ", sorted_z_values)
                
                x := int_from_bits(sorted_x_values[:])
                y := int_from_bits(sorted_y_values[:])
                z := int_from_bits(sorted_z_values[:])
                
                fmt.printf("=> %v %v %v = %v", x, super_op, y, z)
                switch super_op {
                case "+": if x + y == z do break outer
                case "&": if x & y == z do break outer
                }
            }
        }
        
        for i in 0..<len(swap_gates) {
            swap_gates[i] = (swap_gates[i] + 1) % len(all_gates)
            if swap_gates[i] != 0 do break
            if i == len(swap_gates) - 1 do break outer
        }
    }
    
    result_names: [dynamic]string
    defer {
        for name in result_names do delete(name)
        delete(result_names)
    }
    
    for name in sorted_z_names {
        for swap_gate_i in swap_gates {
            if all_gates[swap_gate_i].out == name {
                append(&result_names, fmt.aprintf("%s", name))
            }
        }
    }
    
    return strings.join(result_names[:], ",")
}

int_from_bits :: proc(bits: []u8) -> int {
    result := 0
    for val, i in bits {
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
        result := execute(transmute(string)input, runner.swap_pairs, runner.super_op)
        defer delete(result)
        
        fmt.printf("%v -> %v", runner.file_path, result)
        defer fmt.println()
        expected_result, has_expected_result := runner.expected_result.?
        if has_expected_result {
            fmt.printf(" (expected %v)", expected_result)
            if strings.compare(expected_result,  result) != 0 {
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
