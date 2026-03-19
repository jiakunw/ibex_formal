#!/bin/bash
INSNS="add sub and or xor sll srl sra slt sltu"

for insn in $INSNS; do
    echo "=== insn_${insn} ==="
    sed "s/INSN_PLACEHOLDER/${insn}/g" script.tcl > _run.tcl
    rm -rf jgproject
    jg -batch _run.tcl 2>&1 | tee log_${insn}.txt
done

echo "=== SUMMARY ==="
grep "proven\|cex\|FAILED" log_*.txt
