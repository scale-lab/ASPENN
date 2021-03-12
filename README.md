ASPENN
Contains verilog files for generating an ASPENN circuit.



SNN_simulation_Cpp
Contains the simulation files for an SNN circuit emulator pre-trained on the MNIST dataset. Weights provided in files, and hard-coded in the simulation file. Achieved ~98.4% accuracy on the MNIST dataset. 
Contains:
Simulation: Simulation coded in <snn_binary.cpp>. Parameters and file names hardcoded in this progam. Will need to recompile program if desired to change parameters.
Executable: Pre-set executable in <snn_binary.exe>. Run from the command line using: > snn_binary.exe
Weight Files: Files containing the pretrained weights for an SNN. Stored as CSV with each line representing all the weights connected to a receiving neuron. File names hard-coded in snn_binary.exe
Test Files: Image data and labels for a test set of MNIST digits

