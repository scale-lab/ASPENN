function res = weights2mem(nn, radix, tile_size, matrix_size, filename)
    layers = length(nn.W);
    for layer = 1:layers
        fid = fopen( [filename, num2str(layer), '.txt'], 'wt' );
        s = nn.size(layer);
        r = nn.size(layer+1);
        offset = mod(r, tile_size);
        if offset ~= 0  
            offset = tile_size-offset;
            W = [nn.W{layer}; zeros(offset, s)];
        else
            W = nn.W{layer};
        end
        for ii=1:((r+offset)/tile_size)
            for jj=1:s
                memLine = [];
                for kk=tile_size:-1:1
                    weight = num2bin_2c(W((ii-1)*tile_size+kk, jj), radix);
                    weight = num2str(weight);
                    weight = weight(:,1:3:end);
                    memLine = [memLine weight];
                end
                fprintf( fid, '%s\n', memLine);
            end  
        end
        fclose(fid);
    end    
    res = 1;
end