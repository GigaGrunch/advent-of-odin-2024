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

current_operand :: proc(using interpreter: ^Interpreter) -> int {
    return int(program[instruction_ptr + 1])
}

@(test)
test_interpreter :: proc(t: ^testing.T) {
    interpreter := Interpreter {
        program = []u8 { 2, 4 },
    }
    op_code, op_code_ok := current_op_code(&interpreter)
    testing.expect(t, op_code_ok)
    testing.expect_value(t, op_code, Op_Code.bst)
    testing.expect_value(t, current_operand(&interpreter), 4)
    interpreter.instruction_ptr += 2 // TODO: use step proc
    op_code, op_code_ok = current_op_code(&interpreter)
    testing.expect(t, !op_code_ok)
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
