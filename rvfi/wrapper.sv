
// wrapper.sv

// Formal verification wrapper for Ibex RISC-V core
// Connects ibex_top to riscv-formal RVFI checker infrastructure
//
// Usage: compile with +define+RVFI +define+RISCV_FORMAL_XLEN=32
//        +define+RISCV_FORMAL_ILEN=32 +define+RISCV_FORMAL_NRET=1

module rvfi_wrapper (
    // basics   
    input  logic        clock,
    input  logic        reset,

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
    input  logic        irq_nm,

    // ================================================================
    // Standard RVFI outputs (riscv-formal interface)
    // ================================================================
    output logic        rvfi_valid,
    output logic [63:0] rvfi_order,
    output logic [31:0] rvfi_insn,
    output logic        rvfi_trap,
    output logic        rvfi_halt,
    output logic        rvfi_intr,
    output logic [ 1:0] rvfi_mode,
    output logic [ 1:0] rvfi_ixl,
    output logic [ 4:0] rvfi_rs1_addr,
    output logic [ 4:0] rvfi_rs2_addr,
    output logic [31:0] rvfi_rs1_rdata,
    output logic [31:0] rvfi_rs2_rdata,
    output logic [ 4:0] rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    output logic [31:0] rvfi_pc_rdata,
    output logic [31:0] rvfi_pc_wdata,
    output logic [31:0] rvfi_mem_addr,
    output logic [ 3:0] rvfi_mem_rmask,
    output logic [ 3:0] rvfi_mem_wmask,
    output logic [31:0] rvfi_mem_rdata,
    output logic [31:0] rvfi_mem_wdata
);

    // ================================================================
    // CPU output signals (driven by ibex_top)
    // ================================================================

    logic        instr_req;
    logic [31:0] instr_addr;
    logic        data_req;
    logic        data_we;
    logic [ 3:0] data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;

    // ================================================================
    // Outstanding request trackers
    // ================================================================

    logic [1:0] instr_outstanding;
    always_ff @(posedge clock) begin
        if (reset)
            instr_outstanding <= 2'd0;
        else
            instr_outstanding <= instr_outstanding
                + {1'b0, (instr_req && instr_gnt)}
                - {1'b0, instr_rvalid};
    end

    logic [1:0] data_outstanding;
    always_ff @(posedge clock) begin
        if (reset)
            data_outstanding <= 2'd0;
        else
            data_outstanding <= data_outstanding
                + {1'b0, (data_req && data_gnt)}
                - {1'b0, data_rvalid};
    end

    // ================================================================
    // Bus protocol assumes — Instruction bus
    // ================================================================

    // No grant without request
    assume property (@(posedge clock) disable iff (reset)
        !instr_req |-> !instr_gnt
    );

    // No rvalid without outstanding request
    assume property (@(posedge clock) disable iff (reset)
        instr_outstanding == 2'd0 |-> !instr_rvalid
    );

    // Don't exceed max outstanding (Ibex prefetch buffer: 2)
    assume property (@(posedge clock) disable iff (reset)
        instr_outstanding <= 2'd2
    );

    // ================================================================
    // Bus protocol assumes — Data bus
    // ================================================================

    // No grant without request
    assume property (@(posedge clock) disable iff (reset)
        !data_req |-> !data_gnt
    );

    // No rvalid without outstanding request
    assume property (@(posedge clock) disable iff (reset)
        data_outstanding == 2'd0 |-> !data_rvalid
    );

    // Don't exceed max outstanding (Ibex LSU: 2 for unaligned)
    assume property (@(posedge clock) disable iff (reset)
        data_outstanding <= 2'd2
    );

    // ================================================================
    // ibex_top instantiation
    // ================================================================

    ibex_top #(
        .PMPEnable        (1'b0),
        .PMPGranularity   (0),
        .PMPNumRegions    (1),
        .MHPMCounterNum   (1),
        .RV32E            (1'b0),
        .RV32M            (ibex_pkg::RV32MFast),
        .RV32B            (ibex_pkg::RV32BNone),
        .RV32ZC           (ibex_pkg::RV32Zca),
        .RegFile          (ibex_pkg::RegFileFF),
        .BranchTargetALU  (1'b0),
        .WritebackStage   (1'b0),
        .ICache           (1'b0),
        .ICacheECC        (1'b0),
        .ICacheScramble   (1'b0),
        .BranchPredictor  (1'b0),
        .DbgTriggerEn     (1'b0),
        .SecureIbex       (1'b0)
    ) u_ibex_top (
        // Clock and reset
        .clk_i                  (clock),
        .rst_ni                 (~reset),

        // Constants
        .test_en_i              (1'b0),
        .ram_cfg_icache_tag_i   ('0),
        .ram_cfg_rsp_icache_tag_o  (),
        .ram_cfg_icache_data_i  ('0),
        .ram_cfg_rsp_icache_data_o (),
        .hart_id_i              (32'h0),
        .boot_addr_i            (32'h0000_0000),

        // Instruction bus
        .instr_req_o            (instr_req),
        .instr_gnt_i            (instr_gnt),
        .instr_rvalid_i         (instr_rvalid),
        .instr_addr_o           (instr_addr),
        .instr_rdata_i          (instr_rdata),
        .instr_rdata_intg_i     (7'b0),
        .instr_err_i            (instr_err),

        // Data bus
        .data_req_o             (data_req),
        .data_gnt_i             (data_gnt),
        .data_rvalid_i          (data_rvalid),
        .data_we_o              (data_we),
        .data_be_o              (data_be),
        .data_addr_o            (data_addr),
        .data_wdata_o           (data_wdata),
        .data_wdata_intg_o      (),
        .data_rdata_i           (data_rdata),
        .data_rdata_intg_i      (7'b0),
        .data_err_i             (data_err),

        // Interrupts (unconstrained)
        .irq_software_i         (irq_software),
        .irq_timer_i            (irq_timer),
        .irq_external_i         (irq_external),
        .irq_fast_i             (irq_fast),
        .irq_nm_i               (irq_nm),

        // Scramble (disabled)
        .scramble_key_valid_i   (1'b0),
        .scramble_key_i         ('0),
        .scramble_nonce_i       ('0),
        .scramble_req_o         (),

        // Debug (disabled)
        .debug_req_i            (1'b0),
        .crash_dump_o           (),
        .double_fault_seen_o    (),

        // RVFI — standard signals to wrapper ports
        .rvfi_valid             (rvfi_valid),
        .rvfi_order             (rvfi_order),
        .rvfi_insn              (rvfi_insn),
        .rvfi_trap              (rvfi_trap),
        .rvfi_halt              (rvfi_halt),
        .rvfi_intr              (rvfi_intr),
        .rvfi_mode              (rvfi_mode),
        .rvfi_ixl               (rvfi_ixl),
        .rvfi_rs1_addr          (rvfi_rs1_addr),
        .rvfi_rs2_addr          (rvfi_rs2_addr),
        .rvfi_rs1_rdata         (rvfi_rs1_rdata),
        .rvfi_rs2_rdata         (rvfi_rs2_rdata),
        .rvfi_rd_addr           (rvfi_rd_addr),
        .rvfi_rd_wdata          (rvfi_rd_wdata),
        .rvfi_pc_rdata          (rvfi_pc_rdata),
        .rvfi_pc_wdata          (rvfi_pc_wdata),
        .rvfi_mem_addr          (rvfi_mem_addr),
        .rvfi_mem_rmask         (rvfi_mem_rmask),
        .rvfi_mem_wmask         (rvfi_mem_wmask),
        .rvfi_mem_rdata         (rvfi_mem_rdata),
        .rvfi_mem_wdata         (rvfi_mem_wdata),

        // RVFI — Ibex-specific (not needed by checker, leave unconnected)
        .rvfi_rs3_addr               (),
        .rvfi_rs3_rdata              (),
        .rvfi_ext_pre_mip            (),
        .rvfi_ext_post_mip           (),
        .rvfi_ext_nmi                (),
        .rvfi_ext_nmi_int            (),
        .rvfi_ext_debug_req          (),
        .rvfi_ext_debug_mode         (),
        .rvfi_ext_rf_wr_suppress     (),
        .rvfi_ext_mcycle             (),
        .rvfi_ext_mhpmcounters       (),
        .rvfi_ext_mhpmcountersh      (),
        .rvfi_ext_ic_scr_key_valid   (),
        .rvfi_ext_irq_valid          (),
        .rvfi_ext_expanded_insn_valid(),
        .rvfi_ext_expanded_insn      (),
        .rvfi_ext_expanded_insn_last (),

        // Control
        .fetch_enable_i              (ibex_pkg::IbexMuBiOn),
        .alert_minor_o               (),
        .alert_major_internal_o      (),
        .alert_major_bus_o           (),
        .core_sleep_o                (),
        .scan_rst_ni                 (~reset),

        // Lockstep/Shadow (SecureIbex=0, unused)
        .lockstep_cmp_en_o           (),
        .data_req_shadow_o           (),
        .data_we_shadow_o            (),
        .data_be_shadow_o            (),
        .data_addr_shadow_o          (),
        .data_wdata_shadow_o         (),
        .data_wdata_intg_shadow_o    (),
        .instr_req_shadow_o          (),
        .instr_addr_shadow_o         ()
    );

endmodule