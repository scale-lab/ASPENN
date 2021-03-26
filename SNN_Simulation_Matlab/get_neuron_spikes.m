function [nn] = get_neuron_spikes(nn, test_x, test_y, opts, neuron, ix_img, radix, filename)
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
num_updates_layer2 = [];
num_updates_layer3 = [];
num_updates_layerOut = [];
num_spikes = 0;
% Time-stepped simulation
max_spikes = 0;
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
            for jj = 1:10000
                sum_spikes = sum(nn.layers{ii-1}.spikes(jj,:));
                num_spikes = num_spikes + sum_spikes*nn.size(ii-1);
                %updates = ceil(sum_spikes/63);
                switch ii
                    case 2
                        num_updates_layer2 = [num_updates_layer2 sum_spikes];
                    case 3
                        num_updates_layer3 = [num_updates_layer3 sum_spikes];
                    case 4
                        num_updates_layerOut = [num_updates_layerOut sum_spikes];
                end
            end
            % Add input to membrane potential
            nn.layers{ii}.mem = nn.layers{ii}.mem + impulse;
            % Check for spiking
            nn.layers{ii}.spikes = nn.layers{ii}.mem >= opts.threshold;
            max_check = max(sum(nn.layers{ii}.spikes,2));
            if max_check > max_spikes
                max_spikes = max_check;
            end
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
disp(max_spikes)

store_spike = nn.layers{3}.spikes;
store_weight = nn.W{end-1};

spike_row = store_spike(ix_img, :);
weight_row = store_weight(neuron,spike_row);
disp(sum(weight_row));
analysis = analyze_weights(weight_row', radix);
%disp(analysis)
disp(num_spikes/10000)

figure
histogram(num_updates_layer2, 'Normalization', 'probability')
title('Layer 2')
figure
histogram(num_updates_layer3, 'Normalization', 'probability')
title('Layer 3')
figure
histogram(num_updates_layerOut, 'Normalization', 'probability')
title('Layer 4')

C = [356.668    2.35367e-5  137e-12; ...
     469.3      2.48127e-5  137e-12; ...
     581.932    2.60383e-5  137e-12; ...
     694.564    2.72638e-5  137e-12; ...
     807.196    2.84892e-5  137e-12; ...
     919.828    2.97147e-5  137e-12];
A = [425.186    9.00658e-5  1243e-12; ...
     496.989    1.02198e-4  1243e-12; ...
     568.8      1.1156e-4   1243e-12; ...
     642.472    1.24823e-4  1308e-12; ...
     711.45     1.36654e-4  1312e-12; ...
     780.915    1.46693e-4  1246e-12];
[E2,As2] = optimize_code_size(nn.size(2), num_updates_layer2, C, A, [3 8])
[E3,As3] = optimize_code_size(nn.size(3), num_updates_layer3, C, A, [3 8])
[Eout,Asout] = optimize_code_size(nn.size(4), num_updates_layerOut, C, A, [3 8])
%writematrix(weight_row', ['double_' filename ]);
%writematrix_fp(weight_row', radix, ['fp_' filename]);
    
% Get answer
[~, guess_idx] = max(nn.layers{end}.sum_spikes');
acc = sum(guess_idx==ans_idx)/size(test_y,1)*100;
fprintf('\nFinal spiking accuracy: %2.2f%%\n', acc);
end
