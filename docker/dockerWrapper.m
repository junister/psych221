classdef dockerWrapper
    %DOCKER Unified way to call docker containers for iset
    %   An attempt to resolve at least some of the myriad platform issues
    %   Not clear whether to make this generic or just for pbrt, in which
    %   case we could handle the isnative binary case also?
    %
    %   Can probably roll the piDockerConfig code in here also.

    % Original by David Cardinal, Stanford University, September, 2021.

    % Example of what we need to generate prior to running:
    %     'docker run -ti --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt'
    %   "docker run -i --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt"

    % docker containers don't keep running on Windows unless we force them:
    % e.g.: docker run -it --name Assimp-1351 <volumes> <image> ...
    %sh -c "assimp export <args> && ping -t localhost > NUL"
    properties
        dockerContainerName = '';
        dockerImageName =  'camerasimulation/pbrt-v4-cpu:latest';
        dockerContainerType = 'linux'; % default, even on Windows
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
        
        function dockerImageName = getPBRTGPUImage()

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
        end


        function containerName = getContainer(containerType)
            persistent containerPBRTGPU;
            %persistent containerPBRTCPU;
            switch containerType
                case 'PBRT-GPU'
                    if isempty(containerPBRTGPU)
                        containerPBRTGPU = dockerWrapper.startPBRTGPU();
                    end
                    [status, result] = system(sprintf("docker ps | grep %s", containerPBRTGPU));
                    if strlength(result) == 0
                        containerPBRTGPU = dockerWrapper.startPBRTGPU();
                    end
                    containerName = containerPBRTGPU;
                otherwise
                    warning("No container found");

            end
        end

        function gpuContainer = startPBRTGPU()
            useImage = dockerWrapper.getPBRTGPUImage();

            % gpu version of pbrt needs to have access to optix and nvidia
            cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
                '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
                '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
            if ispc
                uName = 'Windows';
            else
                uName = getenv('USER');
                cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
                '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
                '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
            end
            gpuContainer = ['pbrt-gpu-' uName];
            % remove any existing container with the same name as it might
            % be old
            [status, result] = system(sprintf('docker container rm -f %s', gpuContainer));

            % Starting as background we need to allow for all scenes
            workDir = fullfile(piRootPath(), "local");
            volumeMap = sprintf("-v %s:%s", workDir, workDir);
            placeholderCommand = 'bash';

            % set up the baseline command
            dockerCommand = sprintf('docker run -d -it --gpus 1 --name %s -p 8010:81 %s', gpuContainer, volumeMap);
            cmd = sprintf('%s %s %s %s', dockerCommand, cudalib, useImage, placeholderCommand);

            [status, result] = system(cmd);
            if status == 0
                return;
            else
                warning("Failed to start Docker container %s with message: %s", gpuContainer, result);
            end
        end

        function [status, result] = render(renderCommand, outputFolder)
            useContainer = dockerWrapper.getContainer('PBRT-GPU');
            
            % okay this is a hack!
            renderCommand = replaceBetween(renderCommand, 1,4, 'pbrt --gpu ');

            containerRender = sprintf("docker exec -it %s sh -c 'cd %s && %s'",useContainer, outputFolder, renderCommand);
            [status, result] = system(containerRender);
        end
    end

    methods
        function obj = dockerWrapper()
            %Docker Construct an instance of this class
            %   Detailed explanation goes here
            % default for flags
            if ispc
                obj.dockerFlags = '-i --rm';
            else
                obj.dockerFlags = '-ti --rm';
            end
        end

        function output = convertPathsInFile(obj, input)
            % for depth or other files that have embedded "wrong" paths
        end

        function output = pathToLinux(obj, inputPath)

            if ispc
                if isequal(fullfile(inputPath), inputPath)
                    % assume we have a drive letter
                    output = inputPath(3:end);
                else
                    output = strrep(output, '\','/');
                end
            else
                output = strrep(inputPath, '\','/');
            end

        end

        function [outputArg, result] = run(obj)
            %RUN Execute Docker command

            % Set up the output folder.  This folder will be mounted by the Docker
            % image if needed. Some commands don't need one:
            if ~isequal(obj.outputFile, '')
                outputFolder = fileparts(obj.outputFile);

                %if isequal(obj.command, 'pbrt')
                %    % maybe this is now de-coupled from the working folder?
                %    if(~exist(outputFolder,'dir'))
                %        error('We need an absolute path for the working folder.');
                %    end
                %    pbrtFile = obj.outputFile;
                %end
                % not sure if this is general enough?
                pbrtFile = obj.outputFile;
                [~,currName,~] = fileparts(pbrtFile);
            else
                % need currName?
            end
            % Make sure renderings folder exists
            if (isequal(obj.command,'pbrt'))
                if(~exist(fullfile(outputFolder,'renderings'),'dir'))
                    mkdir(fullfile(outputFolder,'renderings'));
                end
            end


            builtCommand = obj.dockerCommand; % baseline
            if ispc
                flags = strrep(obj.dockerFlags, '-ti ', '-i ');
                flags = strrep(flags, '-it ', '-i ');
                flags = strrep(flags, '-t', '-t ');
            else
                flags = obj.dockerFlags;
            end
            builtCommand = [builtCommand ' ' flags];

            if ~isequal(obj.dockerContainerName, '')
                builtCommand = [builtCommand obj.dockerContainerName];
            end

            if ~isequal(obj.workingDirectory, '')
                builtCommand = [builtCommand ' -w ' obj.pathToLinux(obj.workingDirectory)];
            end
            if ~isequal(obj.localVolumePath, '') && ~isequal(obj.targetVolumePath, '')
                if ispc && ~isequal(obj.dockerContainerType, 'windows')
                    % need to rewrite targetVolumePath
                    %folderBreak = split(obj.targetVolumePath, filesep());
                    %fOut = strcat('/', [char(folderBreak(end-1)) '/' char(folderBreak(end))]);
                    fOut = obj.pathToLinux(obj.targetVolumePath);
                else
                    fOut = obj.targetVolumePath;
                end
                builtCommand = [builtCommand ' -v ' obj.localVolumePath ':' fOut];
            end
            if isequal(obj.dockerImageName, '')
                %assume running container
                builtCommand = [builtCommand ''];
            else
                builtCommand = [builtCommand ' ' obj.dockerImageName];
            end
            if ~isequal(obj.command, '')
                builtCommand = [builtCommand ' ' obj.command];
            end

            %in cases where we don't use an of prefix then inputfile comes before
            %outputfile
            if ispc
                outFileName = obj.pathToLinux(obj.outputFile);
            else
                outFileName = obj.outputFile;
            end
            if ~isequal(obj.outputFilePrefix, '')
                builtCommand = [builtCommand ' ' obj.outputFilePrefix ' ' outFileName];
                if ~isequal(obj.inputFile, '')
                    if ispc
                        fOut = obj.pathToLinux(obj.inputFile);
                    else
                        fOut = obj.inputFile;
                    end
                else
                    %not sure if we need this?
                    folderBreak = split(obj.outputFile, filesep());
                    if isequal(obj.command, 'assimp export')
                        % total hack, need to decide when we need
                        % folder paths
                        fOut = strcat(char(folderBreak(end)));
                    else
                        fOut = obj.pathToLinux(obj.outputFile);
                    end
                end
                builtCommand = [builtCommand ' ' fOut];
            else
                if ~isequal(obj.inputFile, '')
                    if ispc
                        fOut = obj.pathToLinux(obj.inputFile);
                    else
                        fOut = obj.inputFile;
                    end
                    builtCommand = [builtCommand ' ' fOut];
                    builtCommand = [builtCommand ' ' obj.outputFilePrefix ' ' outFileName];
                end
            end


            if ispc
                [outputArg, result] = system(builtCommand, '-echo');
            else
                [outputArg, result] = system(buitCommand);
            end

        end
    end
end

