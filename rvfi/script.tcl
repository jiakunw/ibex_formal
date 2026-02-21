# ============================================================
# JasperGold TCL script for Ibex riscv-formal ISA verification
# ============================================================

clear -all

# Paths
set ROOT_PATH   /home/jw4865/ibex-formal
set RTL_PATH    ${ROOT_PATH}/rtl
set VENDOR_PATH ${ROOT_PATH}/vendor/lowrisc_ip/ip
set TARGET_PATH ${ROOT_PATH}/rvfi
set CHECKS_PATH ${TARGET_PATH}/checks
set INSNS_PATH  ${TARGET_PATH}/insns

# Defines
set DEFINES [list \
    +define+RVFI \
    +define+RISCV_FORMAL_NRET=1 \
    +define+RISCV_FORMAL_XLEN=32 \
    +define+RISCV_FORMAL_ILEN=32 \
    +define+RISCV_FORMAL_INSN_MODEL=rvfi_insn_add \
]

# Include paths (for prim_assert.sv, rvfi_macros.vh, etc.)
set INCDIR [list \
    +incdir+${VENDOR_PATH}/prim/rtl \
    +incdir+${ROOT_PATH}/vendor/lowrisc_ip/dv/sv/dv_utils \
    +incdir+${TARGET_PATH} \
]

# ============================================================
# Analyze — order matters (packages first, then modules)
# ============================================================

# 1. Packages
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${RTL_PATH}/ibex_pkg.sv

# 2. OpenTitan primitives (ibex_top depends on these)
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${VENDOR_PATH}/prim/rtl/prim_assert.sv \
    ${VENDOR_PATH}/prim_generic/rtl/prim_ram_1p_pkg.sv \
    ${VENDOR_PATH}/prim_generic/rtl/prim_clock_gating.sv \
    ${VENDOR_PATH}/prim_generic/rtl/prim_buf.sv \
    ${VENDOR_PATH}/prim/rtl/prim_secded_pkg.sv \
    ${VENDOR_PATH}/prim_generic/rtl/prim_flop.sv

# 3. Ibex RTL
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${RTL_PATH}/ibex_alu.sv \
    ${RTL_PATH}/ibex_compressed_decoder.sv \
    ${RTL_PATH}/ibex_controller.sv \
    ${RTL_PATH}/ibex_counter.sv \
    ${RTL_PATH}/ibex_cs_registers.sv \
    ${RTL_PATH}/ibex_csr.sv \
    ${RTL_PATH}/ibex_decoder.sv \
    ${RTL_PATH}/ibex_ex_block.sv \
    ${RTL_PATH}/ibex_fetch_fifo.sv \
    ${RTL_PATH}/ibex_id_stage.sv \
    ${RTL_PATH}/ibex_if_stage.sv \
    ${RTL_PATH}/ibex_load_store_unit.sv \
    ${RTL_PATH}/ibex_multdiv_fast.sv \
    ${RTL_PATH}/ibex_multdiv_slow.sv \
    ${RTL_PATH}/ibex_pmp.sv \
    ${RTL_PATH}/ibex_prefetch_buffer.sv \
    ${RTL_PATH}/ibex_register_file_ff.sv \
    ${RTL_PATH}/ibex_wb_stage.sv \
    ${RTL_PATH}/ibex_core.sv \
    ${RTL_PATH}/ibex_top.sv

# 4. riscv-formal checker + instruction spec
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${TARGET_PATH}/rvfi_macros.vh 

# insn_add.v is verilog file not sv
analyze -verilog {*}${DEFINES} {*}${INCDIR} \
    ${INSNS_PATH}/insn_add.v
    
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${CHECKS_PATH}/rvfi_insn_check.sv

# 5. Wrapper and testbench
analyze -sv09 {*}${DEFINES} {*}${INCDIR} \
    ${TARGET_PATH}/wrapper.sv \
    ${CHECKS_PATH}/rvfi_testbench.sv

# ============================================================
# Elaborate
# ============================================================

elaborate -top rvfi_testbench

# ============================================================
# Clock and reset
# ============================================================

clock clock
reset reset

# ============================================================
# Prove
# ============================================================

get_design_info

set_prove_time_limit 300s
prove -all

# ============================================================
# Report
# ============================================================

report