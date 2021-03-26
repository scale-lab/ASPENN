function binnums = enumerate_binary(n)
    if n == 1
        binnums = [0;1];
    else
        b = enumerate_binary(n-1);
        binnums = [b; b];
        binnums = [[zeros(2^(n-1),1); ones(2^(n-1),1)], binnums];
    end

end