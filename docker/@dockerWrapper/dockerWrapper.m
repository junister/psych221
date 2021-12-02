classdef dockerWrapper
    %DOCKER Class providing accelerated pbrt on GPU performance
    %
    % In principle, when simply used for render acceleration
    % on a GPU, it should be user-transparent.
    %
    % It operates by having piRender() call it to determine the
    % best docker image to run (ideally one with GPU support).
    %
    % It then starts that image as a persistent, named, container.
    % Calls to piRender() will then use dockerWrapper to do the
    % rendering in the running container, avoiding startup overhead
    % (which is nearly 20 seconds per render without this approach).

    % FUTURE: Potenially unified way to call docker containers for iset
    %   An attempt to resolve at least some of the myriad platform issues
    %   Not clear whether to make this generic or just for pbrt, in which
    %   case we could handle the isnative binary case also?
    %
    %   Can probably roll the piDockerConfig code in here also.

    % Original by David Cardinal, Stanford University, September, 2021.

    % Example of what we need to generate prior to running:
    %     'docker run -ti --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt'
    %   "docker run -i --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt"

    properties
        dockerContainerName = '';
        dockerImageName =  'digitalprodev/pbrt-v4-cpu:latest';
        dockerImageRender = ''; % set based on local machine
        dockerContainerType = 'linux'; % default, even on Windows
        gpuRendering = true;
        useContext = '';
        remoteImage = '';
        workingDirectory = '';
        localVolumePath = '';
        targetVolumePath = '';
        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';
        command = 'pbrt';
        inputFile = '';
        outputFile = 'pbrt_output.exr';
        outputFilePrefix = '--outfile';
    end

    methods (Static)

        [dockerExists, status, result] = exists() % separate file

        function output = pathToLinux(inputPath)

            if ispc
                if isequal(fullfile(inputPath), inputPath)
                    % assume we have a drive letter
                    output = inputPath(3:end);
                    output = strrep(output, '\','/');
                else
                    output = strrep(inputPath, '\','/');
                end
            else
                output = inputPath;
            end

        end



    end
    methods
        function ourContainer = startPBRT(obj, processorType)
            if isequal(processorType, 'GPU')
                useImage = obj.getPBRTImage('GPU');
            else
                useImage = obj.getPBRTImage('CPU');
            end
            rng('shuffle'); % make random numbers random
            uniqueid = randi(20000);
            if ispc
                cudalib = ''; % we build them into the docker image
                uName = ['Windows' int2str(uniqueid)];
            else
                uName = getenv('USER');
                cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
            end
            if isequal(processorType, 'GPU')
                ourContainer = ['pbrt-gpu-' uName];
            else
                ourContainer = ['pbrt-cpu-' uName];
            end

            % remove any existing container with the same name as it might
            % be old
            %[status, result] = system(sprintf('docker container rm -f %s', gpuContainer));

            % Starting as background we need to allow for all scenes
            workDir = fullfile(piRootPath(), 'local');
            volumeMap = sprintf("-v %s:%s", workDir, dockerWrapper.pathToLinux(workDir));
            placeholderCommand = 'bash';

            % set up the baseline command
            if isequal(processorType, 'GPU')
                dCommand = sprintf('docker run -d -it --gpus 1 --name %s -p 8010:81 %s', ourContainer, volumeMap);
                cmd = sprintf('%s %s %s %s', dCommand, cudalib, useImage, placeholderCommand);
            else
                dCommand = sprintf('docker run -d -it --name %s -p 8010:81 %s', ourContainer, volumeMap);
                cmd = sprintf('%s %s %s', dCommand, useImage, placeholderCommand);
            end

            [status, result] = system(cmd);
            if status == 0
                return;
            else
                warning("Failed to start Docker container with message: %s", result);
            end
        end




        function obj = dockerWrapper(varargin)
            %Docker Construct an instance of this class
            %   Detailed explanation goes here
            % default for flags
            if ispc
                obj.dockerFlags = '-i --rm';
            else
                obj.dockerFlags = '-ti --rm';
            end
            obj.config(varargin{:});

        end

        function containerName = getContainer(obj,containerType)
            persistent containerPBRTGPU;
            persistent containerPBRTCPU;
            switch containerType
                case 'PBRT-GPU'
                    if isempty(containerPBRTGPU)
                        containerPBRTGPU = obj.startPBRT('GPU');
                    end
                    [status, result] = system(sprintf("docker ps | grep %s", containerPBRTGPU));
                    if strlength(result) == 0
                        containerPBRTGPU = obj.startPBRT('GPU');
                    end
                    containerName = containerPBRTGPU;
                case 'PBRT-CPU'
                    if isempty(containerPBRTCPU)
                        containerPBRTCPU = obj.startPBRT('CPU');
                    end
                    [status, result] = system(sprintf("docker ps | grep %s", containerPBRTCPU));
                    if strlength(result) == 0
                        containerPBRTCPU = obj.startPBRT('CPU');
                    end
                    containerName = containerPBRTCPU;
                otherwise
                    warning("No container found");

            end
        end

        function dockerImageName = getPBRTImage(obj, processorType)

            if isequal(processorType, 'GPU')

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
                            dockerImageName = 'digitalprodev/pbrt-v4-gpu-ampere-bg';
                            %dockerContainerName = 'pbrt-gpu';
                        case {'geforcegtx1080',  'nvidiageforcegtx1080'}
                            dockerImageName = 'digitalprodev/pbrt-v4-gpu-pascal';
                            %dockerContainerName = 'pbrt-gpu';
                        otherwise
                            warning('No compatible docker image for GPU model: %s, will run on CPU', GPUModel);
                            dockerImageName = 'digitalprodev/pbrt-v4-cpu';
                            %dockerContainerName = '';
                    end

                else
                    dockerImageName = '';
                end
            else
                dockerImageName = obj.dockerImageName;
            end
        end

        function output = convertPathsInFile(obj, input)
            % for depth or other files that have embedded "wrong" paths
        end

    end
end

