ASPENN
Contains Verilog files for generating an ASPENN circuit. The important modules are listed below:
- snn_top.v: The top level module containing the Controller unit and the Neuron Matrix. Handles data flow and index control.
- neuron_matrix.v: The core computation unit. Contains some number of neuron tiles and directs data into and out of them.
- neuron_tile.v: A grouping of several neurons. Performs the actual neuron computation and controls the low-level neuron operation
- threshold_unit.v: A simple threshold circuit. Determines a neuron's spiking activity.
- compressor.v: Part of the weight accumulator. Performs Stage 1, counter compression.
- skew_offset_add_signed.v: Part of the weight accumulator. Performs Stages 2 and 3, block-save addition and the final CPA addition.
- counters.v: A positive counter.
- counters_neg.v: A negative counter.

To synthesize on of these modules, simply follow the below steps:
- Follow the Genus setup instructions found at: https://github.com/scale-lab/EDA-Scripts
- Edit the primary design file with the desired parameters
	- run the command: > genus -no_gui -batch -files rc_commands_*design*.tcl
	- Genus metric results are found in the "genus_out_CLIFNU" directory
	- The synthesized design file, marked with the "_syn.v" suffix, is also in the "genus_out_CLIFNU" directory
- Verification using the iverilog simulation tool:
	- Edit "tb_<design>.v" with the desired parameters
	- Run pre-synthesis simulation: iverilog tb_*design*.v *design*.v
	- Run post-synthesis simulation: iverilog tb_*design*.v *design*_syn.v gscl45nm.v
		- Make sure to copy the synthesized file from the "genus_out_CLIFNU" directory before running a post-synthesis simulation
	- Display simulation results: vvp a.out

SNN_simulation_Cpp:
ASPENN is emulated using a C++ emulator. This program perfectly emulates an individual neuron circuit, but has the network level data flow controlled through software. This program is used to test spiking activity and accuracy metrics for different neuron configurations, and especially the impact of approximate neuron circuits. This folder also contains the weights files for a pre-trained SNN. 
- snn_binary.cpp: Exact neuron SNN emulator. Achieves ~98.4% accuracy on the MNIST dataset.
- snn_bin_approx.cpp: Approximate SNN emulator. Various approximate designs, configured in the file.
Weight Files: Files containing the pretrained weights for an SNN. Stored as CSV with each line representing all the weights connected to a receiving neuron. File names hard-coded in snn_binary.exe
Test Files: Image data and labels for a test set of MNIST digits

The run this simulation:
1) Modify the parameters in the appropriate simulation.
2) Compile the cpp program with the compiler of your choice.
3) Run the resultant executable in the same folder, so it can access the weight and test files.


SNN_Simulation_Matlab:
ASPENN is trained in Matlab, and many of the weights and memory files used during simulation are generated here as well. The files that perform training and data processin are primarily contained within this sub-directory. Most of the training files have been adapted from the work of Neil et al [https://github.com/dannyneil/spiking_relu_conversion.git]. ASPENN specific processing programs are included, and summarized below.
- example_fcn: The primary training script. Can be used to adjust various network parameters, including layer number, layer size, and timestep number.
- write_mnist: Writes the MNIST image set and label set to text files. Also writes the trained weights to text files.
- write_matrix: Writes a float matrix to a text file.
- write_matrix_fp: Converts a float matrix into a fixed-point binary matrix and writes the converted data to a text file.
- num2bin_2c: Converts a float number to a binary, signed fixed-point number.
- read_weights: Reads a csv file and generates a float matrix.
- image2spikes: Converts a set of MNIST images (represented by a matrix) into a spiking pattern from some number of timesteps, and writes that spiking activity to a set of text files.
- weights2mem: Converts a weight matrix into a properly formatted text file that represents ASPENN's Main Memory subsystem.
- get_neuron_spikes: Gets the spiking activity for a specific neuron at a specific time, and writes that activity to a text file.

To launch this simulation, first execute example_fcn. This trains an SNN on the MNIST dataset and produces several structures containing all relevant pieces of data. This can then be converted into the text files used elsewhere for the Verilog and C++ simulations. 
