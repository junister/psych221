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
        volLocalPath = '';
        volRemotePath = '';
        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';
        command = 'pbrt';
        inFile = ''; 
        outFile = 'pbrt_output.exr';
    end
    
    methods
        function obj = docker(inputArg1,inputArg2)
            %Docker Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
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
        
        function outputArg = run(obj,inputArg)
            %RUN Execute Docker command
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

