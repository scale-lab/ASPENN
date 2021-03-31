function weights = read_weights(filename)
    %{
        Reads a csv text file and converts the data into a matrix
        Inputs:
        - filename [string]: The name of the text file to read
        Outputs:
        - weights [nxm matrix]: The matrix result from reading the file
        indicated by filename.
    %}

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
