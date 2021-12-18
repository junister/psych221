classdef dockerWrapper < handle
    %DOCKER Class providing accelerated pbrt on GPU performance
    %
    % In principle, when simply used for render acceleration
    % on a GPU, it should be user-transparent.
    %
    % It operates by having piRender() call it to determine the
    % best docker image to run (ideally one with GPU support).
    %
    % If the GPU is local, this should be pretty straightforward.
    % Running on a remote GPU is more comples. See below for
    % more information on the required parameters.
    %
    % Either way, we start an image as a persistent, named, container.
    % Calls to piRender() will then use dockerWrapper to do the
    % rendering in the running container, avoiding startup overhead
    % (which is nearly 20 seconds per render without this approach).
    %
    % Parameters used for Remote Rendering
    %
    % remoteMachine -- name of remote machine to render on
    % remoteUser -- username on remote machine (that has key support)
    % remoteContext -- name of docker context pointing to renderer
    % remoteImage -- GPU-specific docker image on remote machine
    % remoteRoot -- needed if different from local piRoot
    %
    % localRoot -- only for WSL -- the /mnt path to the Windows piRoot
    % 
    % Additional Render-specific parameters
    %
    % whichGPU -- for multi-gpu rendering systems
    % 
    % FUTURE: Potenially unified way to call docker containers for iset
    %   An attempt to resolve at least some of the myriad platform issues
    %

    % Original by David Cardinal, Stanford University, September, 2021.

    % Example of remote GPU rendering from a Windows client:
    % ourDocker = dockerWrapper('gpuRendering', true, 'renderContext', 'remote-render','remoteImage', ...
    %    'digitalprodev/pbrt-v4-gpu-ampere-bg', 'remoteRoot','/home/<username>/', ...
    %     'remoteMachine', '<DNS resolvable host>', ...
    %     'remoteUser', '<remote uname>', 'localRoot', '/mnt/c', 'whichGPU', 1);

    % Example of local CPU rendering:
    % ourDocker = dockerWrapper('gpuRendering', false);

    % Example of what we need to generate prior to running from scratch
    % -- Not needed for rendering
    %     'docker run -ti --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt'
    %   "docker run -i --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt"

    properties
        dockerContainerName = '';
        % default image is cpu
        dockerImageName =  'digitalprodev/pbrt-v4-cpu:latest';
        dockerImageRender = ''; % set based on local machine
        dockerContainerType = 'linux'; % default, even on Windows
        gpuRendering = true;

        % these relate to remote/server rendering
        % they overlap while we learn the best way to organize them
        remoteMachine = ''; % for syncing the data
        remoteUser = ''; % use for rsync & ssh/docker
        renderContext = '';
        remoteImage = '';
        remoteRoot = ''; % we need to know where to map on the remote system
        localRoot = ''; % for the Windows/wsl case (sigh)
        workingDirectory = '';
        localVolumePath = '';
        targetVolumePath = '';
        whichGPU = 1; % for multiple GPU configs we can pick one

        %
        relativeScenePath = '/iset/iset3d-v4/local/'; % essentially static
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

        % for switching docker to other (typically remote) context
        % and then back. Static as it is system-wide
        function setContext(useContext)
            if ~isempty(useContext)
                system(sprintf('docker context use %s', useContext));
            else
                system('docker context use default');
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
                uName = ['Windows' int2str(uniqueid)];
            else
                uName = [getenv('USER') int2str(uniqueid)];
            end
                cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
            if isequal(processorType, 'GPU')
                ourContainer = ['pbrt-gpu-' uName];
            else
                ourContainer = ['pbrt-cpu-' uName];
            end

            % remove any existing container with the same name as it might
            % be old
            %[status, result] = system(sprintf('docker container rm -f %s', gpuContainer));

            % Starting as background we need to allow for all scenes
            % if remote then need to figure out correct path
            if ~isempty(obj.remoteRoot)
                mountData = [obj.remoteRoot obj.relativeScenePath];
            elseif ~isempty(obj.remoteMachine)
                mountData = [obj.remoteRoot obj.relativeScenePath];
            else
                if isempty(obj.localRoot)
                    mountData = fullfile(piRootPath(), 'local');
                else
                    mountData = fullfile(obj.localRoot, 'local');
                end
                % I don't think we want this for the local case!
                %if ispc && isequal(obj.dockerContainerType, 'linux')
                %    mountData = dockerWrapper.pathToLinux(mountData);
                %end
            end
            mountData = strrep(mountData,'//','/');
            % is our mount point always the same?
            mountPoint = obj.relativeScenePath;
            %mountPoint = dockerWrapper.pathToLinux(mountData);

            volumeMap = sprintf("-v %s:%s", mountData, mountPoint);
            placeholderCommand = 'bash';

            % set up the baseline command
            if isequal(processorType, 'GPU')
                if isempty(obj.renderContext)
                    contextFlag = '';
                else
                    contextFlag = [' --context ' obj.renderContext];
                end
                dCommand = sprintf('docker %s run -d -it --gpus 1 --name %s  %s', contextFlag, ourContainer, volumeMap);
                cmd = sprintf('%s %s %s %s', dCommand, cudalib, useImage, placeholderCommand);
            else
                dCommand = sprintf('docker run -d -it --name %s %s', ourContainer, volumeMap);
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
                    % Need to switch to render context here!
                    if ~isempty(obj.renderContext)
                        cFlag = ['--context ' obj.renderContext];
                    else
                        cFlag = '';
                    end
                    [~, result] = system(sprintf("docker %s ps | grep %s", cFlag, containerPBRTGPU));
                    if strlength(result) == 0 % doesn't exist, so start one
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

            % if we are told to run on a remote machine with a
            % particular image, that takes precedence.
            if ~isempty(obj.remoteImage)
                dockerImageName = obj.remoteImage;
                return;
            end

            % otherwise we are local and will look for the correct
            % container
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
                        case {'teslat4', 'quadrot2000'}
                            dockerImageName = 'camerasimulation/pbrt-v4-gpu-t4';
                            %dockerContainerName = 'pbrt-gpu';
                        case {'geforcertx3070', 'geforcertx3090', 'nvidiageforcertx3070', 'nvidiageforcertx3090'}
                            dockerImageName = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
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

