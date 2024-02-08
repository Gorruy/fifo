vlib work

vlog -sv ../rtl/fifo.sv
vlog -sv ../tb/scfifo.v
vlog -sv top_tb.sv

vsim -novopt top_tb
add log -r /*
add wave -r *
run -all