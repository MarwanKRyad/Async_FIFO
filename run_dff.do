vlib work
vlog Async_FIFO.v Async_FIFO_tb.v
vsim -voptargs=+acc work.Async_FIFO_tb
add wave *
run -all
