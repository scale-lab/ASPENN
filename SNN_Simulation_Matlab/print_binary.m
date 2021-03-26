function res = print_binary(num)
    res = '';
    for ii=1:length(num)
        if num(ii)
            res = [res '1'];
        else
            res = [res '0'];
        end
    end
end