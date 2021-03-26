function out = analyze_weights(weights, radix)
    r = length(weights);
    c = radix(1);
    data = zeros(r, c);
    for ii=1:r
        data(ii,:) = num2bin_2c(weights(ii), radix);
    end
    numones_col = sum(data);
    numones_total = sum(numones_col);
    probones_col = numones_col / r;
    probones_total = numones_total / (r*c);
    out = [numones_col, probones_col, numones_total, probones_total];
end