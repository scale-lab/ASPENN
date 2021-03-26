function res = writematrix_fp(A, radix, filename)
    r = length(A);
    fid = fopen( filename, 'wt' );
    for ii=1:r
        data = num2bin_2c(A(ii), radix);
        data = num2str(data);
        data = data(:,1:3:end);
        fprintf( fid, '%s\n', data);
    end
    fclose(fid);
    res = 1;
end