function [outspike, outmem] = neuron_IF(spikein, weights, mem, threshold)
    weightsin = weights(spikein);
    impulse = sum(weightsin);
    mempot = mem + impulse;
    outspike = mempot >= threshold;
    if outspike
    	outmem = 0;
    else
        outmem = mempot;
    end
end