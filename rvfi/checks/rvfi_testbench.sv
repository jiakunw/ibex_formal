// rvfi_testbench.sv
// rvfi_testbench for JasperGold
// Adapted from riscv-formal/checks/rvfi_testbench.sv
//
// Original: uses Yosys macros, $initstate, rvfi_seq
// This version: hand-expanded for JG, standard SystemVerilog

module rvfi_testbench (
    input logic clock,
    input logic reset,

    input logic check, // solver picks which cycle to check

    // ================================================================
    // Regular inputs (JG explores all possible values)
    // ================================================================

    // Instruction bus responses
    input  logic        instr_gnt,
    input  logic        instr_rvalid,
    input  logic [31:0] instr_rdata,
    input  logic        instr_err,

    // Data bus responses
    input  logic        data_gnt,
    input  logic        data_rvalid,
    input  logic [31:0] data_rdata,
    input  logic        data_err,

    // Interrupts
    input  logic        irq_software,
    input  logic        irq_timer,
    input  logic        irq_external,
    input  logic [14:0] irq_fast,
    input  logic        irq_nm
);

    // ================================================================
    // RVFI wires (hand-expanded, NRET=1, XLEN=32, ILEN=32)
    // ================================================================

    logic        rvfi_valid;
    logic [63:0] rvfi_order;
    logic [31:0] rvfi_insn;
    logic        rvfi_trap;
    logic        rvfi_halt;
    logic        rvfi_intr;
    logic [ 1:0] rvfi_mode;
    logic [ 1:0] rvfi_ixl;
    logic [ 4:0] rvfi_rs1_addr;
    logic [ 4:0] rvfi_rs2_addr;
    logic [31:0] rvfi_rs1_rdata;
    logic [31:0] rvfi_rs2_rdata;
    logic [ 4:0] rvfi_rd_addr;
    logic [31:0] rvfi_rd_wdata;
    logic [31:0] rvfi_pc_rdata;
    logic [31:0] rvfi_pc_wdata;
    logic [31:0] rvfi_mem_addr;
    logic [ 3:0] rvfi_mem_rmask;
    logic [ 3:0] rvfi_mem_wmask;
    logic [31:0] rvfi_mem_rdata;
    logic [31:0] rvfi_mem_wdata;

    // ================================================================
    // Cycle counter (same logic as original)
    // ================================================================

    logic [7:0] cycle_reg;
    logic [7:0] cycle;

    assign cycle = reset ? 8'd0 : cycle_reg;

    always_ff @(posedge clock) begin
        if (reset)
            cycle_reg <= 1;
        else if (cycle_reg != 8'hff)
            cycle_reg <= cycle_reg + 1;
    end

    // ================================================================
    // CPU wrapper (ibex_top + bus abstraction)
    // ================================================================

    rvfi_wrapper wrapper (
        .clock,
        .reset,
        .instr_gnt,
        .instr_rvalid,
        .instr_rdata,
        .instr_err,
        .data_gnt,
        .data_rvalid,
        .data_rdata,
        .data_err,
        .irq_software,
        .irq_timer,
        .irq_external,
        .irq_fast,
        .irq_nm,
        .rvfi_valid,
        .rvfi_order,
        .rvfi_insn,
        .rvfi_trap,
        .rvfi_halt,
        .rvfi_intr,
        .rvfi_mode,
        .rvfi_ixl,
        .rvfi_rs1_addr,
        .rvfi_rs2_addr,
        .rvfi_rs1_rdata,
        .rvfi_rs2_rdata,
        .rvfi_rd_addr,
        .rvfi_rd_wdata,
        .rvfi_pc_rdata,
        .rvfi_pc_wdata,
        .rvfi_mem_addr,
        .rvfi_mem_rmask,
        .rvfi_mem_wmask,
        .rvfi_mem_rdata,
        .rvfi_mem_wdata
    );

    // ================================================================
    // ISA instruction checker
    //
    // Original uses `RISCV_FORMAL_CHECKER macro (expands to rvfi_insn_check)
    // Original uses `RISCV_FORMAL_RESET_CYCLES for extended reset
    // Original uses `RISCV_FORMAL_CHECK_CYCLE to pick which cycle to check
    //   — in bounded mode: check = (cycle == CHECK_CYCLE)
    //   — in unbounded mode: check is an unconstrained input
    // We use unbounded style: check is unconstrained (solver picks)
    // ================================================================

    localparam RESET_CYCLES = 2;

    rvfi_insn_check checker_inst (
        .clock          (clock),
        .reset          (cycle < RESET_CYCLES),
        .check          (check),
        .rvfi_valid     (rvfi_valid),
        .rvfi_order     (rvfi_order),
        .rvfi_insn      (rvfi_insn),
        .rvfi_trap      (rvfi_trap),
        .rvfi_halt      (rvfi_halt),
        .rvfi_intr      (rvfi_intr),
        .rvfi_mode      (rvfi_mode),
        .rvfi_ixl       (rvfi_ixl),
        .rvfi_rs1_addr  (rvfi_rs1_addr),
        .rvfi_rs2_addr  (rvfi_rs2_addr),
        .rvfi_rs1_rdata (rvfi_rs1_rdata),
        .rvfi_rs2_rdata (rvfi_rs2_rdata),
        .rvfi_rd_addr   (rvfi_rd_addr),
        .rvfi_rd_wdata  (rvfi_rd_wdata),
        .rvfi_pc_rdata  (rvfi_pc_rdata),
        .rvfi_pc_wdata  (rvfi_pc_wdata),
        .rvfi_mem_addr  (rvfi_mem_addr),
        .rvfi_mem_rmask (rvfi_mem_rmask),
        .rvfi_mem_wmask (rvfi_mem_wmask),
        .rvfi_mem_rdata (rvfi_mem_rdata),
        .rvfi_mem_wdata (rvfi_mem_wdata)
    );

endmodule