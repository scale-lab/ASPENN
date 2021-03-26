function weights = read_weights(filename)
    fid = fopen(filename);
    tline = fgetl(fid);
    tsplit = split(tline, ',');
    n = length(tsplit);
    dline = zeros(1,n);
    for ii = 1:n
        dline(ii) = str2double(tsplit{ii});
    end
    weights = dline;
    tline = fgetl(fid);
    while ischar(tline)
        tsplit = split(tline, ',');
        for ii = 1:n
            dline(ii) = str2double(tsplit{ii});
        end
        weights = [weights ; dline];
        tline = fgetl(fid);
    end
    fclose(fid);

end
