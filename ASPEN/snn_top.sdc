#current_design [module name]
#create_clock [get_ports {clk_name }]  -name clk_name -period clk_period(ns) -waveform {rise fall}
current_design snn_top
create_clock [get_ports {clk}]  -name clk -period 2 -waveform {0 1}
set io_delay 0
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [all_inputs]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [all_outputs]