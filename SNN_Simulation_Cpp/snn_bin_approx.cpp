#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <cstdlib> 
#include <cstdio>
#include <ctime> 
#include <math.h>
using namespace std;

#define INPUT_SIZE 784
#define INPUT_LAYER_SIZE 784
#define HIDDEN_LAYER_SIZE 1024
#define OUTPUT_LAYER_SIZE 10
#define SIMULATION_STEP_NUM 10
#define WEIGHT_SIZE 8
#define FRAC_SIZE 8
#define CODE_SIZE 5
#define MEMBRANE_SIZE 16


struct Opts  
{  
	 float t_ref;  
	 float threshold;
	 float dt;
	 float duration;
	 float report_every;
	 float max_rate;
} ;

void read_mnist_labels(char *filename, int labels[], int rows)
{
	int class_num = 10;
	ifstream infile( filename );
	for (int ii = 0; ii < rows; ii++) 
	{
		string s;
		if (!getline( infile, s )) break;

		istringstream ss( s );

		for (int jj = 0; jj < class_num; jj++)
		{
		  string s;
		  if (!getline( ss, s, ',' )) break;
		  if (stoi(s) == 1) labels[ii]= jj;
		}
	}
	infile.close();
}

void negate_binary(bool *binin, int data_size, bool *binout) {
	bool start = false;
	for (int ii = 0; ii < data_size; ii++) {
		if (!start) {
			*(binout + ii) = *(binin + ii);
			start = *(binin + ii);
		} else {
			*(binout + ii) = !(*(binin + ii));
		}
	}
}

void itob_2c(int numin, int data_size, bool *binout) {
	int abs_numin = abs(numin);
	for (int ii = 0; ii < data_size; ii++) {
		binout[ii] = abs_numin % 2;
		abs_numin = floor((double)abs_numin/2.0);
	}
	if (numin < 0) {
		negate_binary(binout, data_size, binout);
	} 
}

void ftob_2c(float numin, int data_size, int frac_size, bool *binout) {
	float abs_numin = fabs(numin);
	int ip = data_size - frac_size;
	bool bit_thresh;
	float power = ip-1;
	float bit_value;
	for (int ii = 0; ii < data_size; ii++) {
		bit_value = pow(2.0,power--);
		bit_thresh = (abs_numin / bit_value) >= 1.0;
		binout[data_size-ii-1] = bit_thresh;
		if (bit_thresh) {
			abs_numin -= bit_value;
		}
	}
	if (signbit(numin)) {
		negate_binary(binout, data_size, binout);
	} 
}

void print_binary(bool *binin, int data_size) {
	for (int ii = 0; ii < data_size; ii++) {
		printf("%c", *(binin+data_size-1-ii) ? '1' : '0');
	}
	printf("\n");
}

void read_csv(char *filename, float data[], int rows, int cols) {
	ifstream infile( filename );
	for (int ii = 0; ii < rows; ii++)
	{
		string s;
		if (!getline( infile, s )) break;
		istringstream ss( s );
		for (int jj = 0; jj < cols; jj++)
		{
		  string s;
		  if (!getline( ss, s, ',' )) break;
		  data[ii*cols+jj]= stof(s);
		}
	}
	infile.close();
}

void read_csv_binary(char *filename, bool *data, int rows, int cols, int data_size, int frac_size) {
	ifstream infile( filename );
	for (int ii = 0; ii < rows; ii++)
	{
		string s;
		if (!getline( infile, s )) break;
		istringstream ss( s );
		for (int jj = 0; jj < cols; jj++)
		{
		  string s;
		  if (!getline( ss, s, ',' )) break;
		  ftob_2c(stof(s), data_size, frac_size, data + data_size*(ii*cols + jj));
		  //data[ii*cols+jj]= stof(s);
		}
	}
	infile.close();
}

void neuron_IF(int in_layer_size, bool* in_spikes, float* in_weights, float in_mem, float threshold, bool* out_spike, float* out_mem) {
	// Calculate neuron impulse by summing weights from spiking synapses
	float impulse = 0;
	for (int synapse = 0; synapse < in_layer_size; synapse++)
	{
		if (*(in_spikes + synapse))
		{
			impulse += *(in_weights + synapse);
		}
	}
	// Sum impulse to membrane potentials
	float mem = in_mem + impulse;
	// Check if potential crosses threshold
	if (mem >= threshold)
	{
		*out_spike = true;
		*out_mem = 0;
	} else {
		*out_spike = false;
		*out_mem = mem;
	}
}

inline void hax(bool ain, bool bin, bool *sum, bool *carry) {
	*sum = (ain) ^ (bin);
	*carry = (ain) && (bin);
}

inline void hax_n(bool ain, bool bin, bool *sum, bool *carry) {
	*sum = (ain) ^ (bin);
	*carry = (ain) && (bin);
}

inline void hax_p(bool ain, bool bin, bool *sum, bool *carry) {
	*sum = !((ain) ^ (bin));
	*carry = (ain) || (bin);
}

inline void fax(bool ain, bool bin, bool cin, bool *sum, bool *carry) {
	bool axb = (ain) ^ (bin);
	*sum = (axb) ^ (cin);
	*carry = ((ain) && (bin)) || ((cin) && (axb));
}

void carry_save_adder(int data_size, bool *ain, bool *bin, bool *cin, bool *sum, bool *carry) {
	for (int ii = 0; ii < data_size; ii++) {
		fax(*(ain+ii), *(bin+ii), *(cin+ii), sum+ii, carry+ii);
	}
}

void ripple_carry_adder(int data_size, bool *ain, bool *bin, bool *sum) {
	bool carry[data_size];
	hax(*ain, *bin, sum, carry);
	for (int ii = 1; ii < data_size; ii++) {
		fax(*(ain+ii), *(bin+ii), *(carry+ii-1), sum+ii, carry+ii);
	}
} 

void add_2x16_approx(int data_size, bool *ain, bool *bin, bool *sum) {
	bool sig_34,sig_37,sig_44,sig_45,sig_46,sig_47,sig_48,sig_49,sig_50,sig_51,sig_52,sig_53,sig_54,sig_55,sig_56,sig_57,sig_58,sig_59,sig_60,sig_61;
	bool sig_62,sig_63,sig_64,sig_65,sig_66,sig_67,sig_68,sig_69,sig_70,sig_71,sig_72,sig_73,sig_74,sig_75,sig_76,sig_77,sig_78,sig_79,sig_80,sig_81;
	bool sig_82,sig_83,sig_84,sig_85,sig_86,sig_87,sig_88,sig_89,sig_90,sig_91,sig_92,sig_93,sig_94,sig_95,sig_96,sig_97,sig_98,sig_99,sig_100,sig_101;
	bool sig_102,sig_103,sig_104,sig_105,sig_106,sig_107,sig_108,sig_109,sig_110;

	sig_34 = !(*(bin+1) && *(bin+1));
	sig_37 = !sig_34;
	sig_44 = *(ain+3) ^ *(bin+3);
	sig_45 = *(ain+3) && *(bin+3);
	sig_46 = sig_44 && *(ain+2);
	sig_47 = sig_44 ^ *(ain+2);
	sig_48 = sig_45 || sig_46;
	sig_49 = *(ain+4) ^ *(bin+4);
	sig_50 = *(ain+4) && *(bin+4);
	sig_51 = sig_49 && sig_48;
	sig_52 = sig_49 ^ sig_48;
	sig_53 = sig_50 || sig_51;
	sig_54 = *(ain+5) ^ *(bin+5);
	sig_55 = *(ain+5) && *(bin+5);
	sig_56 = sig_54 && sig_53;
	sig_57 = sig_54 ^ sig_53;
	sig_58 = sig_55 || sig_56;
	sig_59 = *(ain+6) ^ *(bin+6);
	sig_60 = *(ain+6) && *(bin+6);
	sig_61 = sig_59 && sig_58;
	sig_62 = sig_59 ^ sig_58;
	sig_63 = sig_60 || sig_61;
	sig_64 = *(ain+7) ^ *(bin+7);
	sig_65 = *(ain+7) && *(bin+7);
	sig_66 = sig_64 && sig_63;
	sig_67 = sig_64 ^ sig_63;
	sig_68 = sig_65 || sig_66;
	sig_69 = *(ain+8) ^ *(bin+8);
	sig_70 = *(ain+8) && *(bin+8);
	sig_71 = sig_69 && sig_68;
	sig_72 = sig_69 ^ sig_68;
	sig_73 = sig_70 || sig_71;
	sig_74 = *(ain+9) ^ *(bin+9);
	sig_75 = *(ain+9) && *(bin+9);
	sig_76 = sig_74 && sig_73;
	sig_77 = sig_74 ^ sig_73;
	sig_78 = sig_75 || sig_76;
	sig_79 = *(ain+10) ^ *(bin+10);
	sig_80 = *(ain+10) && *(bin+10);
	sig_81 = sig_79 && sig_78;
	sig_82 = sig_79 ^ sig_78;
	sig_83 = sig_80 || sig_81;
	sig_84 = *(ain+11) ^ *(bin+11);
	sig_85 = *(ain+11) && *(bin+11);
	sig_86 = sig_84 && sig_83;
	sig_87 = sig_84 ^ sig_83;
	sig_88 = sig_85 || sig_86;
	sig_89 = *(ain+12) ^ *(bin+12);
	sig_90 = *(ain+12) && *(bin+12);
	sig_91 = sig_89 & sig_88;
	sig_92 = sig_89 ^ sig_88;
	sig_93 = sig_90 || sig_91;
	sig_94 = *(ain+13) ^ *(bin+13);
	sig_95 = *(ain+13) && *(bin+13);
	sig_96 = sig_94 && sig_93;
	sig_97 = sig_94 ^ sig_93;
	sig_98 = sig_95 || sig_96;
	sig_99 = *(ain+14) ^ *(bin+14);
	sig_100 = *(ain+14) && *(bin+14);
	sig_101 = sig_99 && sig_98;
	sig_102 = sig_99 ^ sig_98;
	sig_103 = sig_100 || sig_101;
	sig_104 = *(ain+15) ^ *(bin+15);
	sig_105 = *(ain+15) && *(bin+15);
	sig_106 = sig_104 && sig_103;
	sig_107 = sig_104 ^ sig_103;

	*(sum+15) = sig_107;
	*(sum+14) = sig_102;
	*(sum+13) = sig_97;
	*(sum+12) = sig_92;
	*(sum+11) = sig_87;
	*(sum+10) = sig_82;
	*(sum+9) = sig_77;
	*(sum+8) = sig_72;
	*(sum+7) = sig_67;
	*(sum+6) = sig_62;
	*(sum+5) = sig_57;
	*(sum+4) = sig_52;
	*(sum+3) = sig_47;
	*(sum+2) = *(bin+2);
	*(sum+1) = sig_37;
	*(sum+0) = *bin;
}

void add5x2_standard(bool numin[10], bool *numout) {
	bool sig0, sig1;
	fax(numin[0], numin[2], numin[4], &sig0, &sig1);
	bool sig2, sig3;
	fax(numin[1], numin[3], numin[5], &sig2, &sig3);
	bool sig4;
	fax(numin[6], numin[8], sig0, numout, &sig4);
	bool sig5, sig6;
	fax(numin[7], numin[9], sig2, &sig5, &sig6);
	bool sig7;
	fax(sig1, sig4, sig5, numout+1, &sig7);
	fax(sig3, sig7, sig6, numout+2, numout+3);
}

void add5x2_approx_p1n2(bool numin[10], bool *numout) {
	bool sig0, sig1;
	fax(numin[0], numin[2], numin[4], numout, &sig1);
	bool sig2, sig3;
	fax(numin[1], numin[3], numin[5], &sig2, &sig3);
	bool sig4, blank0;
	hax_p(numin[6], numin[8], &blank0, &sig4);
	bool sig5, sig6;
	hax_n(numin[7], numin[9], &sig5, &sig6);
	bool sig7;
	fax(sig1, sig4, sig5, numout+1, &sig7);
	fax(sig3, sig7, sig6, numout+2, numout+3);
}

void add5x2_approx_p1n2p4(bool numin[10], bool *numout) {
	bool sig0, sig1;
	fax(numin[0], numin[2], numin[4], numout, &sig1);
	bool sig2, sig3;
	fax(numin[1], numin[3], numin[5], &sig2, &sig3);
	bool sig4, blank0;
	hax_p(numin[6], numin[8], &blank0, &sig4);
	bool sig5, sig6;
	hax_n(numin[7], numin[9], &sig5, &sig6);
	bool sig7;
	fax(sig1, sig4, sig5, numout+1, &sig7);
	hax_p(sig3, sig6, numout+2, numout+3);
}

void add5x2_approx1(bool numin[10], bool *numout) {
	bool sig0, sig1;
	fax(numin[0], numin[2], numin[4], numout, &sig0);
	sig1 = numin[6] && numin[8];
	bool sig2, sig3;
	fax(numin[1], numin[3], numin[5], &sig2, &sig3);
	bool sig4, sig5;
	sig4 = !(numin[7] ^ numin[9]);
	sig5 = numin[7] || numin[9];
	bool sig6;
	fax( sig0, sig1, sig4, &sig6, numout+1);
	fax( sig3, sig5, sig6, numout+3, numout+2);
}

void add5x2_approx2(bool numin[10], bool *numout) {
	bool sig0, sig1;
	fax(numin[0], numin[2], numin[4], numout, &sig0);
	sig1 = numin[6] && numin[8];
	bool sig2, sig3;
	fax(numin[1], numin[3], numin[5], &sig2, &sig3);
	bool sig4, sig5;
	sig4 = !(numin[7] ^ numin[9]);
	sig5 = numin[7] || numin[9];
	fax(sig0, sig1, sig4, numout+1, numout+2);
	*(numout+3) = sig3 && sig5;
}

void skewed_offset_adder(int weight_size, int membrane_size, int code_size, int *counters, bool* in_val, bool* out_val) {
	// Weight_size is even
	// Parameters
	const int skew_size = weight_size + code_size - 1;
	// Counter Compression: weights -> offsets
	int block_count = 0;
	bool offset[code_size];
	bool skewed_offset[skew_size*code_size] = { false };
	for (int ii = 0; ii < weight_size-1; ii++) {
		itob_2c(counters[ii], code_size, offset);
		for (int jj = 0; jj < code_size; jj++) {
			skewed_offset[jj*skew_size + ii + jj] = offset[jj];
		}
	}
	itob_2c(counters[weight_size-1], code_size, offset);
	negate_binary(offset, code_size, offset);
	bool msb_counter_sign = counters[weight_size-1] != 0;
	for (int jj = 0; jj < code_size; jj++) {
		skewed_offset[jj*skew_size + weight_size-1 + jj] = offset[jj];
	}
	
	// Skewed Addition: offsets -> partitioned numbers
	const int block_size = ceil(log2((double)(code_size-1))); 
	const int block_num = ceil(((double) skew_size)/((double) block_size));
	const int part_size = 2*block_size;
	const int part_num = ceil(((double) block_num) / 2.0);
	const int partnum_size = part_size*part_num+block_size;
	
	bool partnum0[membrane_size] = { false };
	bool partnum1[membrane_size] = { false };
	bool block[block_size*code_size];
	for (int ii = 0; ii < block_num; ii++) {
		for (int jj = 0; jj < code_size; jj++) {
			block[2*jj] = skewed_offset[ii*block_size + jj*skew_size];
			block[2*jj+1] = skewed_offset[ii*block_size + jj*skew_size + 1];
		}
		if (ii % 2) {
			add5x2_standard(block, (partnum1+((ii-1)/2)*part_size+2));
		} else {
			add5x2_standard(block, (partnum0+(ii/2)*part_size));
		}
	}
	for (int ii = partnum_size-block_size; ii < partnum_size; ii++) {
		partnum0[ii] = msb_counter_sign;
	}
	for (int ii = partnum_size; ii < membrane_size; ii++) {
		partnum0[ii] = msb_counter_sign;
		partnum1[ii] = false;
	}
	// Final Additions: partitioned numbers + in_val -> out_val
	bool csa_sum[membrane_size] = { false };
	bool csa_carry[membrane_size+1] = { false };
	carry_save_adder(membrane_size, partnum0, partnum1, in_val, csa_sum, csa_carry+1);
	ripple_carry_adder(membrane_size, csa_sum, csa_carry, out_val);
}

void skewed_offset_adder_approx(int weight_size, int membrane_size, int code_size, int *counters, bool* in_val, bool* out_val) {
	// Weight_size is even
	// Parameters
	const int skew_size = weight_size + code_size - 1;
	// Counter Compression: weights -> offsets
	int block_count = 0;
	bool offset[code_size];
	bool skewed_offset[skew_size*code_size] = { false };
	for (int ii = 0; ii < weight_size-1; ii++) {
		itob_2c(counters[ii], code_size, offset);
		for (int jj = 0; jj < code_size; jj++) {
			skewed_offset[jj*skew_size + ii + jj] = offset[jj];
		}
	}
	itob_2c(counters[weight_size-1], code_size, offset);
	negate_binary(offset, code_size, offset);
	bool msb_counter_sign = counters[weight_size-1] != 0;
	for (int jj = 0; jj < code_size; jj++) {
		skewed_offset[jj*skew_size + weight_size-1 + jj] = offset[jj];
	}
	
	// Skewed Addition: offsets -> partitioned numbers
	const int block_size = ceil(log2((double)(code_size-1))); 
	const int block_num = ceil(((double) skew_size)/((double) block_size));
	const int part_size = 2*block_size;
	const int part_num = ceil(((double) block_num) / 2.0);
	const int partnum_size = part_size*part_num+block_size;
	
	bool partnum0[membrane_size] = { false };
	bool partnum1[membrane_size] = { false };
	bool block[block_size*code_size];
	for (int ii = 0; ii < block_num; ii++) {
		for (int jj = 0; jj < code_size; jj++) {
			block[2*jj] = skewed_offset[ii*block_size + jj*skew_size];
			block[2*jj+1] = skewed_offset[ii*block_size + jj*skew_size + 1];
		}
		if (ii % 2) {
			if (ii == 1) {
				add5x2_approx2(block, (partnum1+((ii-1)/2)*part_size+2));
			} else {
				add5x2_standard(block, (partnum1+((ii-1)/2)*part_size+2));
			}
		} else {
			if (ii == 2) {
				add5x2_approx1(block, (partnum0+(ii/2)*part_size));
				//add5x2_standard(block, (partnum0+(ii/2)*part_size));
			} else {
				add5x2_standard(block, (partnum0+(ii/2)*part_size));
			}
		}
	}
	for (int ii = partnum_size-block_size; ii < partnum_size; ii++) {
		partnum0[ii] = msb_counter_sign;
	}
	for (int ii = partnum_size; ii < membrane_size; ii++) {
		partnum0[ii] = msb_counter_sign;
		partnum1[ii] = false;
	}
	// Final Additions: partitioned numbers + in_val -> out_val
	bool csa_sum[membrane_size] = { false };
	bool csa_carry[membrane_size+1] = { false };
	carry_save_adder(membrane_size, partnum0, partnum1, in_val, csa_sum, csa_carry+1);
	add_2x16_approx(membrane_size, csa_sum, csa_carry, out_val);
	//ripple_carry_adder(membrane_size, csa_sum, csa_carry, out_val);
}

void neuron_IF_bin_approx(int in_layer_size, int weight_size, int membrane_size, int code_size,
					bool* in_spikes, bool* in_weights, bool* in_mem,
					bool* out_spike, bool* out_mem) {
	// Calculate neuron impulse by summing weights from spiking synapses
	bool impulse[membrane_size];
	for (int ii = 0; ii < membrane_size; ii++) {
		impulse[ii] = in_mem[ii];
	}
	int counters[weight_size] = {0};
	int block_count = 0;
	const int block_size = pow(2,code_size)-1;
	for (int synapse = 0; synapse < in_layer_size; synapse++) {
		if (*(in_spikes + synapse)) {
			// Count number of ones in each significance column
			block_count++;
			for (int ii = 0; ii < weight_size; ii++) {
				if (*(in_weights + synapse*weight_size + ii)) {
					counters[ii] = counters[ii] + 1;
				}
			}
		}
		if (block_count == block_size) {
			skewed_offset_adder_approx(weight_size, membrane_size, code_size, counters, impulse, impulse);
			for (int ii = 0; ii < weight_size; ii++) {
				counters[ii] = 0;
			}
			block_count = 0;
		}
	}
	bool mem[membrane_size];
	skewed_offset_adder_approx(weight_size, membrane_size, code_size, counters, impulse, mem);
	// Sum impulse to membrane potentials
	// Check if potential crosses threshold
	bool mem_thresh = 0;
	if (!mem[membrane_size-1]) {
		for (int ii = weight_size; ii < membrane_size-1; ii++) {
			if (mem[ii]) {
				mem_thresh = true;
				break;
			}
		}
	}
	if (mem_thresh) {
		*out_spike = true;
		for (int ii = 0; ii < membrane_size; ii++) {
			*(out_mem+ii) = 0;
		}
	} else {
		*out_spike = false;
		for (int ii = 0; ii < membrane_size; ii++) {
			*(out_mem+ii) = mem[ii];
		}
	}
}

int main ()
{
	// Set Random Seed
	srand(static_cast<unsigned int>(time(nullptr))); 
	// Number of MNIST Examples to process
	int num_examples = 1000;
	// Read MNIST Labels
	int *mnist_labels = new int[num_examples];
	char mnist_labels_filename[] = "test_labels.txt";
	read_mnist_labels(mnist_labels_filename, mnist_labels, num_examples);
	// Read MNIST Data
	float *mnist_data = new float[num_examples * INPUT_SIZE];
	char mnist_data_filename[] = "test_data.txt";
	read_csv(mnist_data_filename, mnist_data, num_examples, INPUT_SIZE);
	
	// Neural Net Parameters
	Opts t_opts;
	t_opts.t_ref        = 0.000;
	t_opts.threshold    =   1.0;
	t_opts.dt           = 0.001;
	t_opts.duration     = t_opts.dt*SIMULATION_STEP_NUM;
	t_opts.report_every = 0.001;
	t_opts.max_rate     =   1000;
	//int nn_layerNum = 4;
	//int nn_layerSize[nn_layerNum] = {INPUT_LAYER_SIZE, HIDDEN_LAYER_SIZE, HIDDEN_LAYER_SIZE, OUTPUT_LAYER_SIZE};
	float rescale_fac = 1/(t_opts.dt*t_opts.max_rate);
	
	// Get Neural Net Weight data
	char weights_1[] = "weights_layer1.txt";
	char weights_2[] = "weights_layer2.txt";
	char weights_3[] = "weights_layer3.txt";
	bool *layer_hidden1_weights = new bool[HIDDEN_LAYER_SIZE * INPUT_LAYER_SIZE * WEIGHT_SIZE];
	bool *layer_hidden2_weights = new bool[HIDDEN_LAYER_SIZE * HIDDEN_LAYER_SIZE * WEIGHT_SIZE];
	bool *layer_output_weights = new bool[OUTPUT_LAYER_SIZE * HIDDEN_LAYER_SIZE * WEIGHT_SIZE];
	printf("Start - Reading Weights\n");
	read_csv_binary(weights_1, layer_hidden1_weights, HIDDEN_LAYER_SIZE, INPUT_LAYER_SIZE, WEIGHT_SIZE, FRAC_SIZE);
	read_csv_binary(weights_2, layer_hidden2_weights, HIDDEN_LAYER_SIZE, HIDDEN_LAYER_SIZE, WEIGHT_SIZE, FRAC_SIZE);
	read_csv_binary(weights_3, layer_output_weights, OUTPUT_LAYER_SIZE, HIDDEN_LAYER_SIZE, WEIGHT_SIZE, FRAC_SIZE);
	printf("Done - Reading Weights\n");
	printf("Start - Processing Images\n");
	
	float numspikes_layer0to1 = 0;
	float numspikes_layer1to2 = 0;
	float numspikes_layer2to3 = 0;

	float acc = 0;
	// Run each image through the neural net
	for (int ex = 0; ex < num_examples; ex++)
	{
		// Run Simulation 
		printf("Image: %d\n", ex);
		// Initialize Neuron Layer information
		// Spike Data
		bool *layer_input_spikes = new bool[SIMULATION_STEP_NUM * INPUT_LAYER_SIZE]();
		bool *layer_hidden1_spikes = new bool[SIMULATION_STEP_NUM * HIDDEN_LAYER_SIZE]();
		bool *layer_hidden2_spikes = new bool[SIMULATION_STEP_NUM * HIDDEN_LAYER_SIZE]();
		bool *layer_output_spikes = new bool[SIMULATION_STEP_NUM * OUTPUT_LAYER_SIZE]();
		// Membrane Potentials
		bool *layer_hidden1_mem = new bool[SIMULATION_STEP_NUM * HIDDEN_LAYER_SIZE * MEMBRANE_SIZE]();
		bool *layer_hidden2_mem = new bool[SIMULATION_STEP_NUM * HIDDEN_LAYER_SIZE * MEMBRANE_SIZE]();
		bool *layer_output_mem = new bool[SIMULATION_STEP_NUM * OUTPUT_LAYER_SIZE * MEMBRANE_SIZE]();
		// Output Spike Sum
		int *layer_output_sum_spikes = new int[OUTPUT_LAYER_SIZE]();
		
		// Generate Image Spike Pattern
		for (int t = 0; t < SIMULATION_STEP_NUM; t++)
		{
			for (int p = 0; p < INPUT_SIZE; p++)
			{
				float spike_snapshot = ((float) rand() / (RAND_MAX)) * rescale_fac;
				bool spike = spike_snapshot <= mnist_data[ex*INPUT_SIZE + p];
				layer_input_spikes[t*INPUT_LAYER_SIZE + p] = spike;
				if (spike) {numspikes_layer0to1++;}
			}
		}
		for (int t = 1; t < SIMULATION_STEP_NUM; t++)
		{
			bool *in_spikes;
			bool *in_weights;
			bool *in_mem;
			bool *out_spike;
			bool *out_mem;
			// Remaining layers
			// Hidden Layer 1
			for (int neuron = 0; neuron < HIDDEN_LAYER_SIZE; neuron++)
			{
				in_spikes = layer_input_spikes + (t-1)*INPUT_LAYER_SIZE;
				in_weights = layer_hidden1_weights + WEIGHT_SIZE*(neuron*INPUT_LAYER_SIZE);
				in_mem = layer_hidden1_mem + MEMBRANE_SIZE*((t-1)*HIDDEN_LAYER_SIZE + neuron);
				out_spike = layer_hidden1_spikes + (t*HIDDEN_LAYER_SIZE + neuron);
				out_mem = layer_hidden1_mem + MEMBRANE_SIZE*(t*HIDDEN_LAYER_SIZE + neuron);
				neuron_IF_bin_approx(INPUT_LAYER_SIZE, WEIGHT_SIZE, MEMBRANE_SIZE, CODE_SIZE,
								in_spikes, in_weights, in_mem,
								out_spike, out_mem);
				if (*out_spike) {numspikes_layer1to2++;}
				//printf("Layer: 1, Time: %d, Neuron: %d, Spike: %s, Mem: ", t, neuron, *out_spike ? "HIGH" : "LOW");
				//print_binary(out_mem, MEMBRANE_SIZE);
			}

			// Hidden Layer 2
			for (int neuron = 0; neuron < HIDDEN_LAYER_SIZE; neuron++)
			{
				in_spikes = layer_hidden1_spikes+(t-1)*HIDDEN_LAYER_SIZE;
				in_weights = layer_hidden2_weights + WEIGHT_SIZE*(neuron*HIDDEN_LAYER_SIZE);
				in_mem = layer_hidden2_mem + MEMBRANE_SIZE*((t-1)*HIDDEN_LAYER_SIZE + neuron);
				out_spike = layer_hidden2_spikes + (t*HIDDEN_LAYER_SIZE + neuron);
				out_mem = layer_hidden2_mem + MEMBRANE_SIZE*(t*HIDDEN_LAYER_SIZE + neuron);
				neuron_IF_bin_approx(HIDDEN_LAYER_SIZE, WEIGHT_SIZE, MEMBRANE_SIZE, CODE_SIZE,
								in_spikes, in_weights, in_mem,
								out_spike, out_mem);
				if (*out_spike) {numspikes_layer2to3++;}
				//printf("Layer: 2, Time: %d, Neuron: %d, Spike: %s, Mem: ", t, neuron, *out_spike ? "HIGH" : "LOW");
				//print_binary(out_mem, MEMBRANE_SIZE);
			}
			
			// Output Layer
			for (int neuron = 0; neuron < OUTPUT_LAYER_SIZE; neuron++)
			{
				in_spikes = layer_hidden2_spikes + (t-1)*HIDDEN_LAYER_SIZE;
				in_weights = layer_output_weights + WEIGHT_SIZE*(neuron*HIDDEN_LAYER_SIZE);
				in_mem = layer_output_mem + MEMBRANE_SIZE*((t-1)*OUTPUT_LAYER_SIZE + neuron);
				out_spike = layer_output_spikes + t*OUTPUT_LAYER_SIZE + neuron;
				out_mem = layer_output_mem + MEMBRANE_SIZE*(t*OUTPUT_LAYER_SIZE + neuron);
				neuron_IF_bin_approx(HIDDEN_LAYER_SIZE, WEIGHT_SIZE, MEMBRANE_SIZE, CODE_SIZE,
								in_spikes, in_weights, in_mem,
								out_spike, out_mem);
				if (*out_spike) {
					layer_output_sum_spikes[neuron] =  layer_output_sum_spikes[neuron] + 1;
				}
				//printf("Layer: OUT, Time: %d, Neuron: %d, Spike: %s, Mem: ", t, neuron, *out_spike ? "HIGH" : "LOW");
				//print_binary(out_mem, MEMBRANE_SIZE);
			}
			
		}
		// Determine spiking answer
		int max_class = 0;
		int max_sum_spike = 0;
		for (int spike_class = 0; spike_class < OUTPUT_LAYER_SIZE; spike_class++)
		{
			//printf("Output %d: %d\n", spike_class, *(layer_output_sum_spikes+spike_class));
			if (layer_output_sum_spikes[spike_class] >= max_sum_spike)
			{
				max_class = spike_class;
				max_sum_spike = layer_output_sum_spikes[spike_class];
			}
		}
		// Compare with actual answer
		if (max_class == mnist_labels[ex])
		{
			acc++;
		}
		// Cleanup SNN data matrices
		delete[] layer_input_spikes;
		layer_input_spikes = nullptr;
		delete[] layer_hidden1_spikes;
		layer_hidden1_spikes = nullptr;
		delete[] layer_hidden2_spikes;
		layer_hidden2_spikes = nullptr;
		delete[] layer_output_spikes;
		layer_output_spikes = nullptr;
		delete[] layer_hidden1_mem;
		layer_hidden1_mem = nullptr;
		delete[] layer_hidden2_mem;
		layer_hidden2_mem = nullptr;
		delete[] layer_output_mem;
		layer_output_mem = nullptr;
		delete[] layer_output_sum_spikes;
		layer_output_sum_spikes = nullptr;
	}
	
	printf("Done - Processing Images\n");
	// Determine Accuracy
	float snn_accuracy = acc/num_examples * 100;
	printf("Accuracy: %f", snn_accuracy);
	// Determine Average Spiking Activity
	float avg_spikes_layer0to1 = numspikes_layer0to1/num_examples;
	float avg_spikes_layer1to2 = numspikes_layer1to2/num_examples;
	float avg_spikes_layer2to3 = numspikes_layer2to3/num_examples;
	printf("Avg. Spiking Activity (Layer 0 to 1): %f\n", avg_spikes_layer0to1);
	printf("Avg. Spiking Activity (Layer 1 to 2): %f\n", avg_spikes_layer1to2);
	printf("Avg. Spiking Activity (Layer 2 to 3): %f\n", avg_spikes_layer2to3);
	
	return 0;
}