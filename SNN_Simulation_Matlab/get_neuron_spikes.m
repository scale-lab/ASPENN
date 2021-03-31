function get_neuron_spikes(nn, test_x, test_y, opts, neuron, ix_img, radix, filename)
    %{
        Extracts the spiking activity for a single neuron in a single
        timestep and writes that activity to a file
        Inputs:
        - nn [struct]: A trained SNN structure
        - test_x [nxm float matrix]: A set of MNIST images. n images of size m.
        - test_y [nx1 integer matrix]: A set of MNIST labels.
        - opts [struct]: A trained SNN simulation opts structure.
        - neuron [integer]: The neuron to select
        - ix_img [integer]: The image index of text_x to extract from.
        - radix [2x1 integer vector]: the dimensions of the fixed point
        representation to convert to. First entry is the total size of the
        number, the second entry is the size of the non-integer component.
        - tile_size [integer]: The number of neurons per tile in ASPENN.
        - matrix_size [integer]: The number of tiles per matrix in ASPENN.
        - filename [string]: The name of the file to write to.
    %}

dt = opts.dt;
nn.performance = [];
num_examples = size(test_x,1);

% Initialize network architecture
for ii = 1 : numel(nn.size)
    blank_neurons = zeros(num_examples, nn.size(ii));
    nn.layers{ii}.mem = blank_neurons;
    nn.layers{ii}.refrac_end = blank_neurons;        
    nn.layers{ii}.sum_spikes = blank_neurons;
end

% Precache answers
[~,   ans_idx] = max(test_y');

for t=dt:dt:opts.duration
        % Create poisson distributed spikes from the input images
        %   (for all images in parallel)
        rescale_fac = 1/(dt*opts.max_rate);
        spike_snapshot = rand(size(test_x)) * rescale_fac;
        inp_image = spike_snapshot <= test_x;
        
        max_check = max(sum(inp_image,2));
        if max_check > max_spikes
            max_spikes = max_check;
        end
        
        nn.layers{1}.spikes = inp_image;
        nn.layers{1}.sum_spikes = nn.layers{1}.sum_spikes + inp_image;
        for ii = 2 : numel(nn.size)
            % Get input impulse from incoming spikes
            impulse = nn.layers{ii-1}.spikes*nn.W{ii-1}';
            % Add input to membrane potential
            nn.layers{ii}.mem = nn.layers{ii}.mem + impulse;
            % Check for spiking
            nn.layers{ii}.spikes = nn.layers{ii}.mem >= opts.threshold;
            % Reset
            nn.layers{ii}.mem(nn.layers{ii}.spikes) = 0;
            % Ban updates until....
            nn.layers{ii}.refrac_end(nn.layers{ii}.spikes) = t + opts.t_ref;
            % Store result for analysis later
            nn.layers{ii}.sum_spikes = nn.layers{ii}.sum_spikes + nn.layers{ii}.spikes;            
        end
        if(mod(round(t/dt),round(opts.report_every/dt)) == round(opts.report_every/dt)-1)
            [~, guess_idx] = max(nn.layers{end}.sum_spikes');
            acc = sum(guess_idx==ans_idx)/size(test_y,1)*100;
            fprintf('Time: %1.3fs | Accuracy: %2.2f%%.\n', t, acc);
            nn.performance(end+1) = acc;
        else
            fprintf('.');     
        end
end


store_spike = nn.layers{3}.spikes;
store_weight = nn.W{end-1};

spike_row = store_spike(ix_img, :);
weight_row = store_weight(neuron,spike_row);


writematrix(weight_row', ['double_' filename ]);
writematrix_fp(weight_row', radix, ['fp_' filename]);
    
% Get answer
[~, guess_idx] = max(nn.layers{end}.sum_spikes');
acc = sum(guess_idx==ans_idx)/size(test_y,1)*100;
fprintf('\nFinal spiking accuracy: %2.2f%%\n', acc);
end
