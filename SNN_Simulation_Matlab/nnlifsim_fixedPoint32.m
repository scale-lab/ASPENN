function nn=nnlifsim_fixedPoint32(nn, test_x, test_y, opts)
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

% Time-stepped simulation
for t=dt:dt:opts.duration
        % Create poisson distributed spikes from the input images
        %   (for all images in parallel)
        rescale_fac = 1/(dt*opts.max_rate);
        spike_snapshot = rand(size(test_x)) * rescale_fac;
        inp_image = spike_snapshot <= test_x;
        
        nn.layers{1}.spikes = inp_image;
        nn.layers{1}.sum_spikes = nn.layers{1}.sum_spikes + inp_image;
        nn.layers{1}.sum_spikes = fi(nn.layers{1}.sum_spikes,1,16,8);
        for ii = 2 : numel(nn.size)
            % Get input impulse from incoming spikes            
            impulse = nn.layers{ii-1}.spikes*nn.W{ii-1}';
            impulse = fi(impulse,1,16,8);
            % Add input to membrane potential
            nn.layers{ii}.mem = nn.layers{ii}.mem + impulse;
            nn.layers{ii}.mem = fi(nn.layers{ii}.mem,1,16,8);
            % Check for spiking
            nn.layers{ii}.spikes = nn.layers{ii}.mem >= opts.threshold;
            % Reset
            nn.layers{ii}.mem(nn.layers{ii}.spikes) = 0;
            % Ban updates until....
            nn.layers{ii}.refrac_end(nn.layers{ii}.spikes) = t + opts.t_ref;
            % Store result for analysis later
            nn.layers{ii}.sum_spikes = nn.layers{ii}.sum_spikes + nn.layers{ii}.spikes;    
            nn.layers{ii}.sum_spikes = fi(nn.layers{ii}.sum_spikes,1,16,8);
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
    
    
% Get answer
[~, guess_idx] = max(nn.layers{end}.sum_spikes');
acc = sum(guess_idx==ans_idx)/size(test_y,1)*100;
fprintf('\nFinal spiking accuracy: %2.2f%%\n', acc);
end


