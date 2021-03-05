puts "================="
puts "Synthesis Started"
date
puts "================="

# config
#--------------
set DESIGN full_neuron_PIF_signed
set OUT_DIR "./genus_out_CLIFNU"
set_db stdout_log $OUT_DIR/genus_CLIFNU.log
set_db command_log $OUT_DIR/genus_CLIFNU.cmd
# effort to use in synthesis; express = fastest, medium = default, high = slowest, but best
set_db syn_global_effort high

#load the library
#------------------------------
set_db library { gscl45nm.lib }

#load and elaborate the design
#------------------------------
read_hdl full_neuron_PIF_signed.v
read_hdl neuron_PIF.v
read_hdl thresholdUnit.v
read_hdl add_skewed_offset_OAAT_signed.v
read_hdl skew_offset_add_signed.v
read_hdl find_offset_OAAT.v
read_hdl counters.v
read_hdl counters_neg.v
read_hdl add2x16_approx.v
read_hdl add5x2_approx1.v
read_hdl add5x2_approx2.v
read_hdl fullAdder.v
read_hdl halfAdder.v

elaborate $DESIGN
check_design $DESIGN -unresolved
timestat Elaboration

#specify timing and design constraints
#--------------------------------------
read_sdc $DESIGN.sdc

set_db information_level 2
#set_db auto_ungroup none
#synthesize the design
#---------------------
# map to generic gates
syn_generic $DESIGN              
timestat SynGeneric
# map to library gates
syn_map $DESIGN                 
timestat SynMap
# optimize
syn_opt $DESIGN                 
timestat SynOpt

#analyze design
#------------------
report area > ./${OUT_DIR}/${DESIGN}_area.rpt
report gates > ./${OUT_DIR}/${DESIGN}_gates.rpt
report timing > ./${OUT_DIR}/${DESIGN}_timing.rpt
report power > ./${OUT_DIR}/${DESIGN}_power.rpt
#export design
#-------------
write_hdl -mapped > ./${OUT_DIR}/${DESIGN}_syn.v
write_hdl -mapped > ./${DESIGN}_syn.v
write_sdc > ./${OUT_DIR}/${DESIGN}_syn.sdc
write_script > ./${OUT_DIR}/${DESIGN}_syn_constraints.g

timestat FINAL

puts "====================="
puts "Synthesis Finished :)"
date
puts "====================="
quit