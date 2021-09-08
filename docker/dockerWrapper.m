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
            
            if isequal(fullfile(inputPath), inputPath)
                % assume we have a drive letter
                output = inputPath(3:end);
                output = strrep(output, '\','/');
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
                flags = strrep(obj.dockerFlags, '-ti', '-i');
                flags = strrep(flags, '-it', '-i');
            else
                flags = obj.dockerFlags;
            end
            builtCommand = [builtCommand ' ' flags];
            
            if ~isequal(obj.dockerContainerName, '')
                builtCommand = [builtCommand ' --name ' obj.dockerContainerName];
            end
            
            if ~isequal(obj.workingDirectory, '')
                builtCommand = [builtCommand ' -w ' pathToLinux(obj.workingDirectory)];
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
                outputArg = -1;
                return;
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
                    
                    if isequal(obj.command, 'assimp export')
                        % total hack, need to decide when we need
                        % folder paths
                        
                        fOut = strcat(char(folderBreak(end)));
                    else
                        fOut = strcat('/', [char(folderBreak(end-2)) '/' char(folderBreak(end-1)) '/' char(folderBreak(end))]);
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

