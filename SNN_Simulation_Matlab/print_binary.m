function res = print_binary(num)
    %{
        Converts a list of binary data into a string representing that
        binary number.
        Inputs:
        - num [nx1 vector]: Vector of binary data representing a
        fixed-point binary number.
        Outputs:
        - res [string]: String representing the value of num.
    %}
    res = '';
    for ii=1:length(num)
        if num(ii)
            res = [res '1'];
        else
            res = [res '0'];
        end
    end
end