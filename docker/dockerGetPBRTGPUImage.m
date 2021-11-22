function dockerImageName = dockerGetPBRTGPUImage()

    % Check whether GPU is available
    [GPUCheck, GPUModel] = system('nvidia-smi --query-gpu=name --format=csv,noheader');
    try
        ourGPU = gpuDevice();
        if ourGPU.ComputeCapability < 5.3 % minimum for PBRT on GPU
            GPUCheck = -1;
        end
    catch
        % GPU acceleration with Parallel Computing Toolbox is not supported on macOS.
    end

    if ~GPUCheck

        % GPU is available
        % switch based on first GPU available
        % really should enumerate and look for the best one, I think
        gpuModels = strsplit(ieParamFormat(strtrim(GPUModel))); 

        switch gpuModels{1}
            case 'teslat4'
                dockerImageName = 'camerasimulation/pbrt-v4-gpu-t4';
                %dockerContainerName = 'pbrt-gpu';
            case {'geforcertx3070', 'geforcertx3090', 'nvidiageforcertx3070', 'nvidiageforcertx3090'}
                dockerImageName = 'camerasimulation/pbrt-v4-gpu-ampere';
                %dockerContainerName = 'pbrt-gpu';
            otherwise
                warning('No compatible docker image for GPU model: %s, will run on CPU', GPUModel);
                dockerImageName = 'camerasimulation/pbrt-v4-cpu';
                %dockerContainerName = '';
        end

    else
        dockerImageName = '';
    end
end

