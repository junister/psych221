function  setGPU(options)
%SETGPU set GPU device & options
    arguments
        options.whichGPU {mustBeNumeric} = 0;
    end
    setpref('docker','whichGPU', options.whichGPU);
    dockerWrapper.reset;
end

