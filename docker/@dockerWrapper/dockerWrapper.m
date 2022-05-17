classdef dockerWrapper < handle
    %DOCKERWRAPPER A class to manage ISET3d-v4 rendering
    %
    % D.Cardinal -- Stanford University -- 2021-2022
    %
    % This class manages how we run PBRT and other tools in docker containers
    % in ISET3d. At present, we manage these cases:
    %
    %   * a remote server with a GPU,
    %   * a remote server with a CPU,
    %   * your local computer with a GPU,
    %   * your local computer with a CPU, and

    %   [FUTURE, TBD:]
    %   * your local computer with PBRT installed and no docker at all.
    %
    % This source code is under active development (May, 2022).
    %
    %
    % USAGE NOTE: To render on multiple servers or processors, create a new
    % instance of dockerWrapper for each. Once an instance is created,
    % it is bound to a specific Docker image and compute context.
    %
    % The dockerWrapper class is used by piWRS() and piRender(). These
    % functions specify the docker images that run either locally or
    % remotely. For instructions on how to set up a computer to run
    % on a remote, see the ISET3d-v4 wiki pages.
    %
    % ** N.B. To run on a remote machine someone must have set up the
    % environment on that machine to match the expectations of ISET3d. 
    %
    % See below for more information on the required parameters.
    %
    % Overview
    %
    % To run on a remote machine, we launch a Docker image on that
    % machine as a persistent, named, container. Calls to piRender()
    % use dockerWrapper to store the name and status of the remote
    % container.  By running in a persistent container, we avoid the
    % startup overhead (which is more than 20 seconds).
    %
    % Because we often use the same remote machine and GPU across
    % multiple days/sessions, the default parameters for docker
    % execution are stored in the Matlab prefs.  These are saved by
    % Matlab between sessions. You can set and get these parameters
    % using the Matlab setpref/getpref commands.
    %    
    % For the moment, we are storing these parameters within the
    % string 'docker', though we are discussing storing them within
    % sthe string 'iset3d'.
    %
    % Default parameters will also be retrieved from prefs using
    %
    %   getpref('docker',<paramName>,[default value]); 
    % 
    %    (or maybe in the future we will shift to)
    %
    %   getpref('iset3d',<paramName>,[default value]);
    %
    % Parameters that need to be passed in or set by default:
    %
    %   remoteMachine -- (if any) name of remote machine to render on
    %   remoteImage   -- (if any) GPU-specific docker image on remote machine
    %   gpuRendering    -- set to true to force GPU rendering
    %                   -- set to false to force CPU rendering
    %                   -- by default will use a local GPU if available
    %
    % Optional parameters
    %  localRender -- Render on your local machine (default false)
    %
    %  remoteUser  -- username on remote machine if different from the
    %                   username on the local machine 
    %  remoteContext -- a docker context that defines the remote
    %                   renderer; only set this if it is  different
    %                   from the default that is created for you
    %                   (unusual)
    %  remoteRoot     -- needed if differs from the return from
    %                    piRootPath 
    %  remoteImageTag -- defaults to :latest
    %  whichGPU    -- for multi-gpu rendering systems, select a specific
    %             GPU on the remote machine. Use device number (e.g.
    %             0, 1, etc.) THe choice -1 defaults, but it is
    %             probably best for you to choose.
    %
    %  localImageTag  -- defaults to :latest
    %  localRoot   -- (only for WSL) the /mnt path to the Windows piRoot
    %
    % Additional NOTES
    %
    % 1. To get rid of any stranded local containers, run on the
    % command line
    %
    %    docker container prune
    %
    % That works for imgtool stranded containers. There can sometimes
    % be stranded rendering containers which may be on your rendering
    % server -- in the event that Matlab doesn't shut down properly.
    % Those can be pruned by running the same command on the server.
    % (or wait for DJC to prune them on the server every few days:))
    %
    % TODO: Potenially unified way to call docker containers for iset
    %   as an attempt to resolve at least some of the myriad platform
    %   issues
    %
    %
    % Examples (needs updates)
    %
    %   1. Remote GPU rendering initialization from a Windows client:
    %
    % ourDocker = dockerWrapper('gpuRendering', true,'remoteImage', ...
    %    <suitable Docker image>, 'remoteRoot','/home/<username>/', ...
    %     'remoteMachine', '<DNS resolvable host>', ...
    %     'remoteUser', '<remote uname>', 'localRoot', <'/mnt/c'>, 'whichGPU', <0>);
    %

    properties (SetAccess = public)

        % by default we assume our container is built to run pbrt
        % this gets changed to run imgtool or assimp, etc.
        command = 'pbrt'; 

        inputFile = '';

        % This should be over-ridden with the appropriate filenams
        % for example: <scene_name>.exr
        outputFile = 'pbrt_output.exr';

        % This is the flag pbrt needs to specify it's output
        % Can be over-ridden if the command takes a different output flag
        outputFilePrefix = '--outfile';
    end

    properties (SetAccess = protected)

        % NOTE: Any property defaults set here should be ones we always
        % want. For ones the user might over-ride, just declare the
        % property here, and set the default value in the Constructor.

        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';

        dockerContainerName = '';
        dockerContainerID = '';

        % these are local things
        % default image is cpu on x64 architecture
        dockerImageName;
        dockerImageRender = '';        % set based on local machine

        % Right now pbrt only supports Linux containers
        dockerContainerType = 'linux'; % default, even on Windows

        % The defaults for these are set in the constructor
        gpuRendering; 
        whichGPU;
        
        % these relate to remote/server rendering
        remoteMachine; % for syncing the data
        remoteUser; % use for rsync & ssh/docker
        remoteImage; % use to specify a GPU-specific image on server
        
        % By default we assume that we want :latest, but :stable is
        % typically also an option incase something is broken
        remoteImageTag;
        remoteRoot; % we need to know where to map on the remote system
        
        % A render context is important for the case where we want to
        % access multiple servers over time (say beluga & mux, or mux &
        % gray, etc). Contexts are created via docker on the local system,
        % and if needed one is created by default
        renderContext;
        localRoot     = ''; % dockerWrapper.defaultLocalRoot();

        workingDirectory = '';
        localVolumePath  = '';
        targetVolumePath = '';

        relativeScenePath;

        localRender;
        localImageTag;

        verbosity;  % 0,1 or 2.  How much to print.  Might change
    end

    methods

        % Constructor method
        function aDocker = dockerWrapper(varargin)
            %Docker Construct an instance of the dockerWrapper class
            %
            %  All dynamic properties should be initialized here!
            %  If they are initialized in properties they get messed up
            %  (DJC).
            %

            aDocker.gpuRendering = getpref('docker', 'gpuRendering', true);
            aDocker.dockerImageName   =  getpref('docker','localImage','');

            aDocker.whichGPU = getpref('docker','whichGPU',0); % -1 is use any

            % these relate to remote/server rendering
            aDocker.remoteMachine  = getpref('docker','remoteMachine',''); % for syncing the data
            aDocker.remoteUser     = getpref('docker','remoteUser',''); % use for rsync & ssh/docker
            aDocker.remoteImage    = getpref('docker','remoteImage',''); % use to specify a GPU-specific image on server
            aDocker.remoteImageTag = 'latest';
            aDocker.remoteRoot     = getpref('docker','remoteRoot',''); % we need to know where to map on the remote system

            aDocker.renderContext = getpref('docker','renderContext','');
            aDocker.relativeScenePath = '/iset/iset3d-v4/local/';
        
            aDocker.localRender = getpref('docker','localRender',false);
            aDocker.localImageTag = 'latest';
            aDocker.localRoot = getpref('docker','localRoot',false);

            aDocker.verbosity = 1;  % 0,1 or 2.  How much to print.  Might change

        % default for flags
            if ispc
                aDocker.dockerFlags = '-i --rm';
            else
                aDocker.dockerFlags = '-ti --rm';
            end

            % I don't think we should fail in a pure default case?
            % Also allow renderString pref for backward compatibility
            if ~isempty(varargin)
                for ii=1:2:numel(varargin)
                    aDocker.(varargin{ii}) = varargin{ii+1};
                end
            end

            if isempty(aDocker.dockerImageName)
                % I think this is the docker image if we run locally.  If
                % the local machine does not have a local Nvidia GPU, we
                % should not try to set with 'GPU'.
                %
                if aDocker.gpuRendering
                    aDocker.dockerImageName = aDocker.getPBRTImage('GPU');
                else
                    aDocker.dockerImageName = aDocker.getPBRTImage('CPU');
                end
                % Check for local consistency here.
            end

        end

        function prefsave(obj)
            % Save the current dockerWrapper settings in the Matlab
            % prefs (under iset3d).  We should probably check if there
            % is a 'docker' prefs and do something about that.

            disp('Saving prefs to "docker"');
            setpref('docker','localRender',obj.localRender);

            setpref('docker','remoteMachine',obj.remoteMachine);
            setpref('docker','remoteRoot',obj.remoteRoot);
            setpref('docker','remoteUser',obj.remoteUser);
            setpref('docker','remoteImageTag',obj.remoteImageTag);

            setpref('docker','gpuRendering',obj.gpuRendering);
            setpref('docker','whichGPU',obj.whichGPU);

            setpref('docker','localImageTag',obj.localImageTag);
            setpref('docker','localRoot',obj.localRoot);

            setpref('docker','verbosity',obj.verbosity);

        end

        function prefread(obj)
            % Read the current dockerWrapper settings in the Matlab
            % prefs (under iset3d).  We should probably check if there
            % is a 'docker' prefs and do something about that.

            disp('Reading prefs from "docker"');
            obj.localRender = getpref('docker','localRender',0);

            obj.remoteMachine = getpref('docker','remoteMachine','');
            obj.remoteRoot    = getpref('docker','remoteRoot','');
            obj.remoteUser    = getpref('docker','remoteUser','');
            obj.remoteImageTag= getpref('docker','remoteImageTag','latest');

            obj.gpuRendering = getpref('docker','gpuRendering',1);
            obj.whichGPU     = getpref('docker','whichGPU',0);

            obj.localImageTag = getpref('docker','localImageTag','latest');
            
            obj.verbosity = getpref('docker','verbosity',1);

        end
    end


    methods (Static=true)

        % Matlab requires listing static functions that are defined in a
        % separate file.  Here are the definitions.  (Static functions do
        % not have an 'obj' argument.
        setParams();
        dockerImage = localImage();
        [dockerExists, status, result] = exists();  % Like piDockerExists
        
        % Default servers
        function useServer = vistalabDefaultServer()
            useServer = 'muxreconrt.stanford.edu';
        end

        function localRoot = defaultLocalRoot()
            if ispc
                localRoot = getpref('docker','localRoot','/mnt/c'); % Windows default            
            else
                localRoot = getpref('docker','localRoot',''); % Linux/Mac default
            end
        end
        % reset - Resets the running Docker containers
        function reset()
            % Calls the method 'cleanup' and sets several parameters
            % to empty.  The cleanup is called if there is a static
            % variable defined for PBRT-GPU and/or PBRT-CPU.

            % TODO: We should remove any existing containers here
            % to sweep up after ourselves.
            if ~isempty(dockerWrapper.staticVar('get','PBRT-GPU',''))
                dockerWrapper.cleanup(dockerWrapper.staticVar('get','PBRT-GPU',''));
                dockerWrapper.staticVar('set', 'PBRT-GPU', '');
            end
            if ~isempty(dockerWrapper.staticVar('get','PBRT-CPU',''))
                dockerWrapper.cleanup(dockerWrapper.staticVar('get','PBRT-CPU',''));
                dockerWrapper.staticVar('set', 'PBRT-CPU', '');
            end

            % Empty out the static variables
            dockerWrapper.staticVar('set', 'cpuContainer', '');
            dockerWrapper.staticVar('set', 'gpuContainer', '');
            dockerWrapper.staticVar('set', 'renderContext', '');
        end

        % cleanup
        function cleanup(containerName)
            if ~isempty(dockerWrapper.staticVar('get','renderContext'))
                contextFlag = sprintf(' --context %s ', dockerWrapper.staticVar('get','renderContext'));
            else
                contextFlag = '';
            end

            % Removes the Docker container in renderContext
            cleanupCmd = sprintf('docker %s rm -f %s', ...
                contextFlag, containerName);
            [status, result] = system(cleanupCmd);

            if status == 0
                sprintf('Removed container %s\n',containerName);
            else
                disp("Failed to cleanup.\n System message:\n %s", result);
            end
        end

        function retVal = staticVar(action, varname, value)
            % Actions are 'set' or anything else.  When using 'get' the
            % value of one of the persistent variables is returned.
            %
            % These variables are 'set' by getRenderer, I think.  We
            % should probably move that 'vistalab' repository and
            % 'getRenderer' into dockerWrapper land (BW).

            persistent gpuContainer;
            persistent cpuContainer;
            persistent renderContext;
            switch varname
                case 'PBRT-GPU'
                    if isequal(action, 'set')
                        gpuContainer = value;
                    end
                    retVal = gpuContainer;
                case 'PBRT-CPU'
                    if isequal(action, 'set')
                        cpuContainer = value;
                    end
                    retVal = cpuContainer;
                case 'renderContext'
                    if isequal(action, 'set')
                        renderContext = value;
                    end
                    retVal = renderContext;
            end
        end

        function output = pathToLinux(inputPath)
            % Can we use fullfile and fileparts instead of requiring this?
            % (BW) 
            % Unfortunately, not. The problem is that on Windows the Docker
            % paths are Linux-format, so the native fullfile and fileparts
            % don't work right. 
            if ispc
                if isequal(fullfile(inputPath), inputPath)
                    if numel(inputPath) > 3 && isequal(inputPath(2:3),':\')
                        % assume we have a drive letter
                        output = inputPath(3:end);
                    else
                        output = inputPath;
                    end
                    output = strrep(output, '\','/');
                else
                    output = strrep(inputPath, '\','/');
                end
            else
                output = inputPath;
            end

        end

        % For switching docker to other (typically remote) context
        % and then back. Static as it is system-wide
        function setContext(useContext)
            if ~isempty(useContext)
                system(sprintf('docker context use %s', useContext));
            else
                system('docker context use default');
            end
        end

    end

    methods (Static = false)
        % These functions are not static; they have an obj argument.

        function ourContainer = startPBRT(obj, processorType)
            % Start the docker container remotely

            verbose = obj.verbosity;
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
            % All our new images currently have libraries pre-loaded
            legacyImages = false;
            if ~legacyImages % contains(useImage, 'shared')
                % we don't need to mount libraries
                cudalib = '';
            else
                cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
                    '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
            end
            if isequal(processorType, 'GPU')
                ourContainer = ['pbrt-gpu-' uName];
            else
                ourContainer = ['pbrt-cpu-' uName];
            end

            % Because we are now running Docker as a background task,
            % we need to be able to re-use it for all scenes
            % so we need to volume map all of /local
            %
            % if running Docker remotely then need to figure out correct path
            %
            % One tricky bit is that on Windows, the mount point is the
            % remote server path, but later we need to use the WSL path for rsync
            %
            % mountPoint is the host fs for iset3d-v4/local
            % mountData is the container path for iset3d-v4/local (normally
            % under /iset)
            %
            if obj.localRender
                mountPoint = fullfile(piRootPath(), 'local/');
            else
                if ~isempty(obj.remoteRoot)
                    mountPoint = [obj.remoteRoot obj.relativeScenePath];
                elseif ~isempty(obj.remoteMachine)
                    mountPoint = [obj.remoteRoot obj.relativeScenePath];
                    warning("Remote mount point for Docker doesn't seem right!");
                end
            end

            mountData = dockerWrapper.pathToLinux(obj.relativeScenePath);

            volumeMap = sprintf("-v %s:%s", mountPoint, mountData);
            placeholderCommand = 'bash';

            % We do not use context for local docker containers
            if obj.localRender
                contextFlag = '';
            else
                % Rendering remotely.
                % Have to track user set context somehow
                % probably static var should be set from prefs
                % automatically...
                if isempty(obj.staticVar('get','renderContext'))
                    contextFlag = [' --context ' getpref('docker','renderContext','')];
                    obj.staticVar('set','renderContext',getpref('docker','renderContext'));
                else
                    contextFlag = [' --context ' obj.staticVar('get','renderContext')];
                end
            end

            if isequal(processorType, 'GPU')
                % want: --gpus '"device=#"'
                gpuString = sprintf(' --gpus device=%s ',num2str(obj.whichGPU));
                dCommand = sprintf('docker %s run -d -it %s --name %s  %s', contextFlag, gpuString, ourContainer, volumeMap);
                cmd = sprintf('%s %s %s %s', dCommand, cudalib, useImage, placeholderCommand);
            else
                dCommand = sprintf('docker %s run -d -it --name %s %s', contextFlag, ourContainer, volumeMap);
                cmd = sprintf('%s %s %s', dCommand, useImage, placeholderCommand);
            end

            [status, result] = system(cmd);
            if verbose > 0
                fprintf("Started Docker (status %d): %s\n", status, cmd);
            end
            if status == 0
                obj.dockerContainerID = result; % hex name for it
                return;
            else
                warning("Failed to start Docker container with message: %s", result);
            end
        end


        function containerName = getContainer(obj,containerType)
            % Get the container name for different types of docker runs.  Either PBRT
            % with a GPU or a CPU
            switch containerType
                case 'PBRT-GPU'
                    if isempty(obj.staticVar('get', 'PBRT-GPU', ''))
                        % Start the container and set its name
                        obj.staticVar('set','PBRT-GPU', obj.startPBRT('GPU'));
                    end
                    
                    % If there is a render context, get it. 
                    if ~isempty(dockerWrapper.staticVar('get','renderContext'))
                        cFlag = ['--context ' dockerWrapper.staticVar('get','renderContext')];
                    else
                        cFlag = '';
                    end

                    % Figure out the container name using a docker ps call
                    % in the context.
                    [~, result] = system(sprintf("docker %s ps | grep %s", cFlag, obj.staticVar('get','PBRT-GPU', '')));
                    
                    if strlength(result) == 0 
                        % Couldn't find it.  So try starting it. Not sure
                        % why we would ever be here?
                        obj.staticVar('set','PBRT-GPU', obj.startPBRT('GPU'));
                    end
                    containerName = obj.staticVar('get','PBRT-GPU', '');

                case 'PBRT-CPU'
                    % Similar logic to above.
                    if isempty(obj.staticVar('get', 'PBRT-CPU', ''))
                        obj.staticVar('set','PBRT-CPU', obj.startPBRT('CPU'));
                    end

                    % Need to switch to render context here!
                    if ~isempty(dockerWrapper.staticVar('get','renderContext'))
                        cFlag = ['--context ' dockerWrapper.staticVar('get','renderContext')];
                    else
                        cFlag = '';
                    end
                    
                    [~, result] = system(sprintf("docker %s ps | grep %s", cFlag, obj.staticVar('get','PBRT-CPU', '')));
                    if strlength(result) == 0
                        obj.staticVar('set','PBRT-CPU', obj.startPBRT('CPU'));
                    end
                    containerName = obj.staticVar('get', 'PBRT-CPU', '');
                otherwise
                    warning("No container found");

            end
        end

        function dockerImageName = getPBRTImage(obj, processorType)
            % Returns the name of the docker image, both for the case of
            % local and remote execution.
            %
            % I think this logic is broken (BW).  
            % The problem on my machine is that dockerImageName is not
            % correct.  That probably happens on dockerWrapper constructor
            % call.

            if ~obj.localRender
                % We are running remotely, we try to figure out which
                % docker image to use.
                if ~isempty(obj.remoteImage)
                    % If a remoteImage is already set, that is what we use
                    dockerImageName = obj.remoteImage;
                    return;
                else
                    % Try to figure it out and return it.
                    obj.getRenderer;
                    dockerImageName = obj.remoteImage;
                    return;
                end
            else
                % If we are here, we are running locally.
                if ~isempty(obj.dockerImageName)
                    % If this is set, use it.                    
                    dockerImageName = obj.dockerImageName;
                    return;
                else
                    % Running locally and no advice from the user.
                    if isequal(processorType, 'GPU') && obj.gpuRendering == true
                        % They have asked for a GPU, so we try to figure
                        % out the local GPU situation.
                        [GPUCheck, GPUModel] = ...
                            system(sprintf('nvidia-smi --query-gpu=name --format=csv,noheader -i %d',obj.whichGPU));
                        try
                            ourGPU = gpuDevice();
                            if ourGPU.ComputeCapability < 5.3 % minimum for PBRT on GPU
                                GPUCheck = -1;
                            end
                        catch
                            % GPU acceleration with Parallel Computing Toolbox is not supported on macOS.
                        end

                        % WE CAN ONLY USE GPUs ON LINUX FOR NOW
                        if ~GPUCheck && ~ispc
                            % A GPU is available.
                            obj.gpuRendering = true;

                            % Switch based on first GPU available
                            % really should enumerate and look for the best one, I think
                            gpuModels = strsplit(ieParamFormat(strtrim(GPUModel)));

                            switch gpuModels{1} % find the model of our GPU
                                case {'teslat4', 'quadrot2000'}
                                    dockerImageName = 'camerasimulation/pbrt-v4-gpu-t4';
                                case {'geforcertx3070', 'nvidiageforcertx3070'}
                                    dockerImageName = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                                case {'geforcertx3090', 'nvidiageforcertx3090'}
                                    dockerImageName = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                                case {'geforcertx2080', 'nvidiageforcertx2080', ...
                                        'geforcertx2080ti', 'nvidiageforcertx2080ti'}
                                    dockerImageName = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                                case {'geforcegtx1080',  'nvidiageforcegtx1080'}
                                    dockerImageName = 'digitalprodev/pbrt-v4-gpu-pascal-shared';
                                otherwise
                                    warning('No compatible docker image for GPU model: %s, running on CPU', GPUModel);
                                    obj.gpuRendering = false;
                                    dockerImageName = dockerWrapper.localImage();
                            end
                        end
                    elseif isequal(processorType, 'CPU')
                        obj.gpuRendering = false;
                        dockerImageName = dockerWrapper.localImage;
                    end
                end
            end
        end

        % Not yet defined.
        %function output = convertPathsInFile(obj, input)
            % for depth or other files that have embedded "wrong" paths
            % implemented someplace, need to find the code!
        %end

        % Inserted from getRenderer.  thisD is a dockerWrapper (obj)
        function getRenderer(thisD)
            %GETRENDERER uses the 'docker' parameters to insert the
            %renderer
            %
            % Description
            %  The initial dockerWrapper is filled in with the user's
            %  preferences from (getpref('docker')).  This method builds on
            %  those to set a few additional parameters that are
            %  site-specific.
            %
            %  VISTALAB GPU Information
            %   The default uses the 3070 on muxreconrt.stanford.edu.
            %   This approach requires having an ssh-key based user login as
            %   described on the wiki page. Specifically, your username & homedir
            %   need to be the same on both machines.
            %
            % Re-write this with the new changes
            %
            %  You can adjust for any differences using dockerWrapper.setParams.
            %  For example,
            %
            %   dockerWrapper.setParams('remoteUser',<remoteUser>);
            %   dockerWrapper.setParams('remoteRoot',<remoteRoot>); % where we will put the iset tree
            %   dockerWrapper.setParams('localRoot',<localRoot>);   % only needed for WSL if not \mnt\c
            %
            % Other options you can specify:
            %
            % If you need to turn-off GPU Rendering set to false
            %
            %   dockerWrapper.setParams('gpuRendering',false);
            %
            % If you are having issues with :latest, you can go back to :stable
            %
            %   dockerWrapper.setParams('remoteImageTag','stable');
            %
            % Change which gpu to use on a server
            %
            %   dockerWrapper.setParams('whichGPU', <#>); % current default is 0 for mux
            %
            % Current GPU Options at vistalab:
            %
            %   muxreconrt:
            %     GPU 0: Nvidia 3070 -- -ampere -- DEFAULT
            %     GPU 1: Nvidia 2080 Ti -- -volta -- setpref('docker','whichGPU', 1);
            %     GPU 2: Nvidia 2080 Ti -- -volta -- setpref('docker','whichGPU', 2);
            %
            % Remote CPU:
            %     mux
            %     (gray??)
            %     (black??)
            %
            % See also
            %   dockerWrapper

            % Sometimes we want to force a local machine
            % This doesn't actually work yet:(
            % forceLocal = getpref('docker','forceLocal', false);

            if thisD.localRender
                % Running on the user's local machine, whether there is a
                % GPU or not.
                thisD.dockerImageName = thisD.localImage;
                return;                

            else
                % Rendering on a remote machine.

                % This sets dockerWrapper parameters that were not already
                % set and creates the docker context.  

                % Docker doesn't allow use of ~ in volume mounts, so we need to
                % make sure we know the correct remote home dir:
                if ispc
                    % This probably should use the thisD.remoteRoot, not
                    % the getpref() method.
                    thisD.remoteRoot = getpref('docker','remoteRoot',getUserName(thisD));
                end

                if isempty(thisD.remoteMachine)
                    % If the remoteMachine was not set in prefs, we get the
                    % default. The user may have multiple opportunities
                    % for this.  For now we default to the
                    % vistalabDefaultServer.
                    thisD.remoteMachine = thisD.vistalabDefaultServer;
                end

                if isempty(thisD.remoteImage)
                    % If we know the remote machine, but not the remote
                    % image, we try fill in the remote Docker image to
                    % use.  We do this depending on the machine and the
                    % GPU.  A different image is needed for each, sigh.
                    %
                    % We should probably catch
                    if isequal(thisD.remoteMachine, thisD.vistalabDefaultServer)
                        % We allow one remote render context
                        thisD.staticVar('set','renderContext', getRenderContext(thisD, thisD.vistalabDefaultServer));
                        switch thisD.whichGPU
                            case {0, -1}
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-ampere-mux-shared';
                            case 1
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                            case 2
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                        end

                        % If the user specified a different tag for the
                        % docker image, use the one they specified.
                        if ~isempty(thisD.remoteImage) && ~contains(thisD.remoteImage,':') % add tag
                            thisD.remoteImage = [thisD.remoteImage, ':', thisD.remoteImageTag];
                        end
                    else
                        % This seems like a problem to me (BW).
                        warning('Unable to identify the remoteImage');
                    end
                end
            end

        end
        
        function userName = getUserName(obj)
            % Reads the user name from a docker wrapper object, or from the
            % system and then sets it in the docker wrapper object.

            % Different methods are needed for different systems.
            if ~isempty(obj.remoteUser)
                % Maybe it is already present in the object
                userName = obj.remoteUser;
                return;
            elseif ispc
                userName = getenv('username');
            elseif ismac
                [~, paddedName] = system('id -un');
                paddedArray = splitlines(paddedName);
                userName = paddedArray{1};
            elseif isunix
                % depressingly we get a newline at the end:(
                [~, paddedName] = system('whoami');
                paddedArray = splitlines(paddedName);
                userName = paddedArray{1};
            else
                error('Unknown system type.');
            end

            % Set it because we have it now!
            obj.remoteUser = userName;

        end

        
        function useContext = getRenderContext(obj, serverName)
            % Get or set-up the rendering context for the docker container
            %
            % A docker context ('docker context create ...') is a set of
            % parameters we define to address the remote docker container
            % from our local computer.
            %
            if ~exist('serverName','var'), serverName = obj.remoteMachine; end

            switch serverName
                case obj.vistalabDefaultServer()
                    % Check that the Docker context exists.
                    checkContext = sprintf('docker context list');
                    [status, result] = system(checkContext);

                    if status ~= 0 || ~contains(result,'remote-mux')
                        % If we do not have it, create it
                        % e.g. ssh://david@muxreconrt.stanford.edu
                        contextString = sprintf(' --docker host=ssh://%s@%s',...
                            getUserName(obj), obj.vistalabDefaultServer);
                        createContext = sprintf('docker context create %s %s',...
                            contextString, 'remote-mux');

                        [status, result] = system(createContext);
                        if status ~= 0 || numel(result) == 0
                            warning("Failed to create context: %s -- Might already exist.",'remote-mux');
                        else
                            disp("Created docker context remote-mux for muxreconrt.stanford.edu")
                        end
                    end
                    useContext = 'remote-mux';
                otherwise
                    warning("Unknown server!");
            end
        end

    end
end



