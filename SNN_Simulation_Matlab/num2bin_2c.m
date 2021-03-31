function [binout] = num2bin_2c(numin, radix)
    %{
        Converts a floating point number to a list representing the signed, fixed-point binary
        representation of that number.
        Inputs:
        - numin [float]: The number to convert.
        - radix [2x1 integer vector]: the dimensions of the fixed point
        representation to convert to. First entry is the total size of the
        number, the second entry is the size of the non-integer component.
        Outputs:
        - binout [nx1 binary vector]: List of binary data that stores the
        binary representation of numin in the proper radix.
    %}
    s = sign(numin);
    n = radix(1);
    fp = radix(2);
    ip = n - fp;
    powers = (ip-1):-1:-fp;
    binout = zeros(length(numin), n);
    temp = numin.*s;
    for ii=1:n
        tv = temp/(2^powers(ii));
        binout(:,ii) = tv >= 1;
        temp = temp - 2^powers(ii)*(tv >= 1);
    end
    for ii = 1:length(numin)
        if s(ii) == -1
            line = binout(ii,:);
            start = 0;
            for jj = n:-1:1
                if not(start)
                    start = line(jj);
                else
                    line(jj) = not(line(jj));
                end
            end
            binout(ii,:) = line;
        end
    end
end