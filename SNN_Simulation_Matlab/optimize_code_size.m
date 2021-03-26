function [E,Ta] = optimize_code_size(n, fsx, C, A, cs_prop)
    max_x = length(fsx);
    E = zeros(cs_prop(2)-cs_prop(1),1);
    Ta = zeros(cs_prop(2)-cs_prop(1),1);
    ts = sum(fsx);
    for ii = cs_prop(1):cs_prop(2)
        index = ii-cs_prop(1)+1;
        block_size = 2^ii-1;
        Ta(index) = C(index,1) + A(index,1);
        counter_energy = ts * C(index,2) * C(index,3);
        update_energy = A(index,2) * A(index,3);
        total_energy = 0;
        for x = 1:max_x
            total_energy = total_energy + fsx(x)*(ceil(x/block_size));
        end
        total_energy = (total_energy*update_energy + counter_energy)*n;
        E(index) = total_energy;
    end
    
end