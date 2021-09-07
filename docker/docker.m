classdef docker
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
    
    properties
        containerName = '';
        containerType = 'linux'; % default, even on Windows
        workingDirectory = '/';
        localVolumePath = '';
        targetVolumePath = '';
        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';
        command = 'pbrt';
        inputFile = '';
        outputFile = 'pbrt_output.exr';
    end
    
    methods
        function obj = docker()
            %Docker Construct an instance of this class
            %   Detailed explanation goes here
            % default for flags
            if ispc
                obj.dockerFlags = '-i --rm';
            else
                obj.dockerFlags = 'ti --rm';
            end
        end
        
        function output = convertPathsInFile(obj, input)
            % for depth or other files that have embedded "wrong" paths
        end
        
        function outputArg = run(obj)
            %RUN Execute Docker command
            %   Detailed explanation goes here
            
            % Set up the output folder.  This folder will be mounted by the Docker
            % image
            outputFolder = fileparts(obj.outputFile);
            
            % maybe this is now de-coupled from the working folder?
            if(~exist(outputFolder,'dir'))
                error('We need an absolute path for the working folder.');
            end
            pbrtFile = obj.outputFile;
            
            [~,currName,~] = fileparts(pbrtFile);
            
            % Make sure renderings folder exists
            if obj.command = 'pbrt'
                if(~exist(fullfile(outputFolder,'renderings'),'dir'))
                    mkdir(fullfile(outputFolder,'renderings'));
                end
            end
            
            
            builtCommand = obj.dockerCommand; % baseline
            builtCommand = [builtCommand ' ' obj.dockerFlags];
            if ~isequal(obj.workingDirectory, '')
                builtCommand = [builtCommand ' -w ' obj.workingDirectory];
            end
            if ~isequal(obj.localVolumePath, '') && ~isequal(obj.targetVolumePath, '')
                if ispc && ~equals(obj.containerType, 'windows')
                    % need to rewrite targetVolumePath
                else
                end
                builtCommand = [builtCommand ' -v ' obj.localVolumePath ':' obj.targetVolumePath];
            end
            if isequal(obj.containerName, '')
                outputArg = -1;
                return;
            else
                builtCommand = [builtCommand ' ' obj.containerName];
            end
            if ~isequal(obj.outFile, '')
                builtCommand = [builtCommand ' --outfile ' obj.outFile];
            end
            if ~isequal(obj.inFile, '')
                builtCommand = [builtCommand ' ' obj.inFile];
            end
            if ispc
                outputArg = system(builtCommand, '-echo');
            else
                outputArg = system(buitCommand);
            end
        end
    end
end

