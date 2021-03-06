function image2spikes(imgs, spike_size, timesteps, max_spikes, filename)
    %{
        Converts a set of MNIST images into a set of text files that
        represents the initial spiking activity of those images.
        Inputs:
        - imgs [nxm float matrix]: A matrix of n images of size m. The
        images to convert.
        - timesteps [integer]: The number of timesteps to compute spikes
        for.
        - max_spikes [integer]: The size of each timestep block.
        - filename [string]: The basic string of the output files.
    %}
    % image2spikes(test_x(1:10,:),10,10,512,'spikeImage_')
    
    [num_img, size_img] = size(imgs);
    
    % Zero Character Array
    spike_data_blank = char(48+zeros(timesteps*max_spikes,spike_size));
    
    % For each image
    for img = 1:num_img
        fid = fopen( [filename, num2str(img), '.txt'], 'wt' );
        spike_header = [];
        spike_data = spike_data_blank;
        for t = 1:timesteps
            rand_img = rand([1,size_img]);
            spike_img = rand_img <= imgs(img,:);
            
            spike_sum = sum(spike_img,2);
            spike_sum = num2bin_2c(spike_sum, [spike_size, 0]);
            spike_sum = num2str(spike_sum);
            spike_sum = spike_sum(:,1:3:end);
            spike_header = [spike_header; spike_sum];
            
            s_index = 1;
            for s = 1:size_img
                if spike_img(s)
                    spike = num2bin_2c(s, [spike_size, 0]);
                    spike = num2str(spike);
                    spike = spike(:,1:3:end);
                    spike_data((t-1)*max_spikes+s_index,:) = spike;
                    s_index = s_index + 1;
                end
            end
        end
        
        for ii = 1:timesteps
           fprintf(fid, '%s\n', spike_header(ii,:));
        end
        for ii = 1:(max_spikes*timesteps)
            fprintf(fid, '%s\n', spike_data(ii,:));
        end
        fclose(fid);
    end
end