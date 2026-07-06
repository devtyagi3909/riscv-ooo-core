`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg reset;
integer errors;
integer saw_issue0;
integer saw_broadcast;


// instantiate CPU
ooo_top cpu(
    .clk(clk),
    .reset(reset)
);


// clock generation
always #5 clk = ~clk;


initial begin

    $dumpfile("waveforms/cpu.vcd");
    $dumpvars(0, cpu_tb);

    clk = 0;
    reset = 1;
    errors = 0;
    saw_issue0 = 0;
    saw_broadcast = 0;

    // During reset, PC should be held at 0 and decode should see the first pair.
    repeat (2) @(posedge clk);
    if (cpu.fetch_inst.pc !== 32'd0) begin
        $display("FAIL: PC should be 0 during reset, got %0d", cpu.fetch_inst.pc);
        errors = errors + 1;
    end
    if (!cpu.decode_inst.valid0 || !cpu.decode_inst.valid1) begin
        $display("FAIL: First fetch pair should decode as valid");
        errors = errors + 1;
    end
    if (cpu.decode_inst.opcode0 !== 4'd9 || cpu.decode_inst.opcode1 !== 4'd9) begin
        $display("FAIL: Expected ADDI/ADDI opcodes for first pair, got %0d/%0d", cpu.decode_inst.opcode0, cpu.decode_inst.opcode1);
        errors = errors + 1;
    end

    reset = 0;

    // First active cycle should allocate two physical destination registers.
    @(posedge clk);
    if (cpu.fetch_inst.pc !== 32'd8) begin
        $display("FAIL: PC should advance by 8 after first active cycle, got %0d", cpu.fetch_inst.pc);
        errors = errors + 1;
    end
    if (cpu.rat_inst.prd_0 !== 6'd32 || cpu.rat_inst.prd_1 !== 6'd33) begin
        $display("FAIL: First dual allocation expected prd_0=32, prd_1=33, got %0d/%0d", cpu.rat_inst.prd_0, cpu.rat_inst.prd_1);
        errors = errors + 1;
    end
    if (cpu.rat_inst.free_ptr !== 6'd34) begin
        $display("FAIL: free_ptr should be 34 after first dual allocation, got %0d", cpu.rat_inst.free_ptr);
        errors = errors + 1;
    end

    // Second active cycle should continue allocating two regs and incrementing PC by 8.
    @(posedge clk);
    if (cpu.fetch_inst.pc !== 32'd16) begin
        $display("FAIL: PC should be 16 after second active cycle, got %0d", cpu.fetch_inst.pc);
        errors = errors + 1;
    end
    if (cpu.rat_inst.prd_0 !== 6'd34 || cpu.rat_inst.prd_1 !== 6'd35) begin
        $display("FAIL: Second dual allocation expected prd_0=34, prd_1=35, got %0d/%0d", cpu.rat_inst.prd_0, cpu.rat_inst.prd_1);
        errors = errors + 1;
    end
    if (cpu.rat_inst.free_ptr !== 6'd36) begin
        $display("FAIL: free_ptr should be 36 after second dual allocation, got %0d", cpu.rat_inst.free_ptr);
        errors = errors + 1;
    end

    // Ensure the back-end path toggles basic scheduler/execute activity.
    repeat (10) begin
        @(posedge clk);
        if (cpu.issue0_valid)
            saw_issue0 = 1;
        if (cpu.broadcast_valid)
            saw_broadcast = 1;
    end

    if (!saw_issue0) begin
        $display("FAIL: Expected scheduler to issue at least one instruction");
        errors = errors + 1;
    end
    if (!saw_broadcast) begin
        $display("FAIL: Expected execution unit to broadcast at least once");
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("PASS: cpu_tb directed verification completed with no errors.");
        $finish;
    end else begin
        $display("FAIL: cpu_tb detected %0d error(s).", errors);
        $finish_and_return(1);
    end

end

endmodule
