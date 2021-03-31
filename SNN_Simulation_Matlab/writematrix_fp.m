function writematrix_fp(A, radix, filename)
    %{
        Converts a float matrix into a fixed-point binary matrix and writes
        that matrix to a file.
        Inputs
        - A [float matrix]: the matrix to convert and write.
        - radix [2x1 vector]: the dimensions of the fixed point
        representation to convert to. First entry is the total size of the
        number, the second entry is the size of the non-integer component.
        - filename [string]: The name of the file to write to.
    %}
    
    r = length(A);
    fid = fopen( filename, 'wt' );
    for ii=1:r
        data = num2bin_2c(A(ii), radix);
        data = num2str(data);
        data = data(:,1:3:end);
        fprintf( fid, '%s\n', data);
    end
    fclose(fid);
end