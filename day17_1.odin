package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"

runners := []struct{file_path: string, expected_result: Maybe(string)} {

}

execute :: proc(input: string) -> string {
    line_it := input
    for line in strings.split_lines_iterator(&line_it) {
        _ = line
    }
    return ""
}

Interpreter :: struct {
    program: []u8,
    register_a: int,
    register_b: int,
    register_c: int,
    instruction_ptr: int,
}

Op_Code :: enum {
    adv,
    bxl,
    bst,
    jnz,
    bxc,
    out,
    bdv,
    cdv,
}

current_op_code :: proc(using interpreter: ^Interpreter) -> (res: Op_Code, ok: bool) {
    if instruction_ptr < len(program) do return Op_Code(program[instruction_ptr]), true
    else do return {}, false
}

current_operand :: proc(using interpreter: ^Interpreter) -> u8 {
    return program[instruction_ptr + 1]
}

combo_operand :: proc(using interpreter: ^Interpreter, raw_operand: u8) -> int {
    switch raw_operand {
    case 0..=3: return int(raw_operand)
    case 4: return register_a
    case 5: return register_b
    case 6: return register_c
    case 7: fmt.printfln("Encountered special value %v", raw_operand)
    }
    panic("Failed to handle combo operand.")
}

execute_op :: proc(using interpreter: ^Interpreter, op_code: Op_Code, operand: u8) -> Maybe(int) {
    switch op_code {
    case .adv: register_a = register_a >> operand
    case .bdv: register_b = register_a >> operand
    case .cdv: register_c = register_a >> operand
    case .bxl: register_b ~= int(operand)
    case .bst: register_b = combo_operand(interpreter, operand) % 8
    case .jnz: if register_a != 0 do instruction_ptr = int(operand) - 2
    case .bxc: register_b ~= register_c
    case .out: return combo_operand(interpreter, operand) % 8
    }
    return nil
}

@(test)
test_interpreter :: proc(t: ^testing.T) {
    interpreter := Interpreter {
        program = []u8 {
            0, 2, // adv
            1, 0b1101, // bxl
            2, 3, // bst with literal 3
            2, 5, // bst with register_b
            3, 8, // jnz (jump to self)
            4, 0, // bxc
            5, 2, // out with literal 2
            5, 6, // out with register_c
            6, 4, // bdv
            7, 6, // cdv
        },
    }
    
    test_next_op :: proc(t: ^testing.T, interpreter: ^Interpreter, expected_op: Op_Code, expected_operand: u8, expected_output: Maybe(int)) {
        op_code, still_running := current_op_code(interpreter)
        testing.expect(t, still_running)
        testing.expect_value(t, op_code, expected_op)
        operand := current_operand(interpreter)
        testing.expect_value(t, operand, expected_operand)
        output := execute_op(interpreter, op_code, operand)
        testing.expect_value(t, output, expected_output)
        interpreter.instruction_ptr += 2 // TODO: use step proc
    }
    
    interpreter.register_a = 8
    test_next_op(t, &interpreter, .adv, 2, nil)
    testing.expect_value(t, interpreter.register_a, 2)
    
    interpreter.register_b = 0b1010
    test_next_op(t, &interpreter, .bxl, 0b1101, nil)
    testing.expect_value(t, interpreter.register_b, 0b0111)
    
    test_next_op(t, &interpreter, .bst, 3, nil)
    testing.expect_value(t, interpreter.register_b, 3)
    
    interpreter.register_b = 10
    test_next_op(t, &interpreter, .bst, 5, nil)
    testing.expect_value(t, interpreter.register_b, 2)
    
    interpreter.register_a = 1
    test_next_op(t, &interpreter, .jnz, 8, nil)
    
    interpreter.register_a = 0
    test_next_op(t, &interpreter, .jnz, 8, nil)
    
    interpreter.register_b = 0b0110
    interpreter.register_c = 0b1011
    test_next_op(t, &interpreter, .bxc, 0, nil)
    testing.expect_value(t, interpreter.register_b, 0b1101)
    
    test_next_op(t, &interpreter, .out, 2, 2)
    
    interpreter.register_c = 12
    test_next_op(t, &interpreter, .out, 6, 4)
    
    interpreter.register_a = 17
    test_next_op(t, &interpreter, .bdv, 4, nil)
    testing.expect_value(t, interpreter.register_b, 1)
    
    interpreter.register_a = 64001
    test_next_op(t, &interpreter, .cdv, 6, nil)
    testing.expect_value(t, interpreter.register_c, 1000)
    
    _, still_running := current_op_code(&interpreter)
    testing.expect_value(t, still_running, false)
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
            if strings.compare(expected_result, result) != 0 do error_count += 1
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
