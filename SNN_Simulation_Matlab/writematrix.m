function res = writematrix(A, filename)
    [r,c] = size(A);
    fid = fopen( filename, 'wt' );
    for ii=1:r
        for jj=1:(c-1)
            data = num2str(A(ii,jj));
            fprintf( fid, '%s,', data);
        end
        data = num2str(A(ii,c));
        fprintf( fid, '%s\n', data);
    end
    fclose(fid);
    res = 1;
end