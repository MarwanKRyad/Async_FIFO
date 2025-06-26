## Clock signal
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk_in]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_in]

## define clock groups to prevent vivado from calculate the hold time between these paths
set_clock_groups -asynchronous -group [get_clocks -include_generated *clk_wr*] -group [get_clocks -include_generated *clk_rd*]
