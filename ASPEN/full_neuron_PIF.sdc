#current_design [module name]
#create_clock [get_ports {clk_name }]  -name clk_name -period clk_period(ns) -waveform {rise fall}
current_design full_neuron_PIF
create_clock [get_ports {clk}]  -name clk -period 10 -waveform {0 5}
set io_delay 0
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [all_outputs]