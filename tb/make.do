vlib work

vlog -sv ../rtl/fifo.sv
vlog -sv ../rtl/ram.v
vlog -sv ../tb/scfifo.v
vlog -sv ~/intelFPGA_lite/18.1/quartus/eda/sim_lib/altera_mf.v
vlog -sv top_tb.sv

vsim -novopt top_tb
add log -r /*
add wave -r *
run -all