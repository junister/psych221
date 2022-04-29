classdef dockerWrapper < handle
    %DOCKERWRAPPER A class that manages rendering methods
    %
    % This class is designed to help manage running ISET3d-v4 in
    % various ways. We hope to include rendering on
    %
    %   * a remote server with a GPU,
    %   * a remote server with a CPU,
    %   * your local computer with a GPU,
    %   * your local computer with a CPU, and
    %   * your local computer with PBRT installed and no docker at all.
    %
    % As of this date, this remains a work-in-progress.
    %
    % This class is used by piRender() to determine the way to run
    % PBRT. The need for this class is that running on remote GPUs or
    % selecting the right Docker container for a particular GPU or a
    % CPU can be complex.
    %
    % Please note:
    % To run on a remote machine someone must have set up the
    % environment on the machine to match the expectations of ISET3d.
    %
    % See below for more information on the required parameters.
    %
    % Running remotely
    %  When run on a remote machine, we launch a Docker image as a
    %  persistent, named, container. Calls to piRender() will use
    %  dockerWrapper to store the name and status of the remote
    %  container.  By running in a persistent container, we avoid the
    %  startup overhead (which is more than 20 seconds).
    %
    %  Parameters used for Remote Rendering
    %
    %   remoteMachine -- name of remote machine to render on
    %   remoteUser    -- username on remote machine (that has key support)
    %   remoteContext -- name of docker context pointing to renderer
    %   remoteImage   -- GPU-specific docker image on remote machine
    %   EXPERIMENTAL: CPU image on remote machine for offloading large
    %                CPU-only renders
    %   remoteRoot -- needed if different from local piRoot
    %
    %   localRoot -- only for WSL -- the /mnt path to the Windows piRoot
    %
    % Additional Render-specific parameters
    %
    % whichGPU -- for multi-gpu rendering systems
    %   use device number (e.g. 0, 1, etc.) or -1 for don't care
    %
    % FUTURE: Potenially unified way to call docker containers for iset
    %   as an attempt to resolve at least some of the myriad platform issues
    %
    % Running locally
    %
    %
    %
    % Additional NOTES:
    %   1. We seem to be leaving a lot of exited docker containers in the
    % docker space.  These are imgtool functions.  Maybe we can stop
    % leaving them around. (Yes:)) In any event, to get rid of them we can run
    %
    %    docker container prune
    %
    % That works for imgtool stranded containers. There can sometimes
    % be stranded rendering containers which may be on your rendering
    % server -- in the event that Matlab doesn't shut down properly.
    % Those can be pruned by running the same command on the server.
    %(or wait for DJC to prune them on the server every few days:))
    %
    % 2. On site-specific settings:
    %   The dockerWrapper will look for a getRenderer() function first.
    %   If it finds one it will use it to set the renderer.
    %   One is not provided directly in ISET3D-v4, so that sites
    %   or organizations can provide their own with local settings,
    %   such as preferred server(s), GPU selection, etc.
    %
    % Original by David Cardinal, Stanford University, September, 2021.
    %
    % Examples (needs updates)
    %
    %   1. Remote GPU rendering initialization from a Windows client:
    %
    % ourDocker = dockerWrapper('gpuRendering', true, 'renderContext', 'remote-render','remoteImage', ...
    %    'digitalprodev/pbrt-v4-gpu-ampere-bg', 'remoteRoot','/home/<username>/', ...
    %     'remoteMachine', '<DNS resolvable host>', ...
    %     'remoteUser', '<remote uname>', 'localRoot', '/mnt/c', 'whichGPU', 0);
    %
    % NOTE: For ease of use you can simply do:
    %   setpref('docker', 'renderString', <same arguments>)
    %     and any new docker containers will use that.
    %
    %   2. Example of local CPU rendering:
    %
    %    ourDocker = dockerWrapper('gpuRendering', false);
    %
    % Example of what we need to generate prior to running from scratch
    % -- Not needed for rendering
    %     'docker run -ti --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt'
    %   "docker run -i --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt"

    properties
        dockerContainerName = '';
        dockerContainerID = '';

        % these are local things
        % default image is cpu on x64 architecture
        dockerImageName   =  dockerWrapper.localImage();
        dockerImageRender = '';        % set based on local machine
        dockerContainerType = 'linux'; % default, even on Windows

        gpuRendering = true;
        whichGPU = getpref('docker','whichGPU',-1);

        % these relate to remote/server rendering
        remoteMachine  = getpref('docker','remoteMachine'); % for syncing the data
        remoteUser     = getpref('docker','remoteUser'); % use for rsync & ssh/docker
        remoteImage    = '';
        remoteImageTag = 'latest';
        remoteRoot     = getpref('docker','remoteRoot'); % we need to know where to map on the remote system

        localRoot = ''; % for the Windows/wsl case (sigh)

        workingDirectory = '';
        localVolumePath  = '';
        targetVolumePath = '';
        % This is set for muxreconrt, but when we are local perhaps it
        % should be something else.
        relativeScenePath = '/iset/iset3d-v4/local/'; % essentially static

        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';
        command = 'pbrt';
        inputFile = '';
        outputFile = 'pbrt_output.exr';
        outputFilePrefix = '--outfile';

        localRender = false;
        localImageTag = 'latest';

    end

    methods

        % Constructor method
        function obj = dockerWrapper(varargin)
            %Docker Construct an instance of this class
            %   Detailed explanation goes here
            % default for flags
            if ispc
                obj.dockerFlags = '-i --rm';
            else
                obj.dockerFlags = '-ti --rm';
            end

            if isempty(varargin), return;
            else
                for ii=1:2:numel(varargin)
                    obj.(varargin{ii}) = varargin{ii+1};
                end
            end

        end
    end


    methods (Static)

        % These are function definitions. Matlab requires listing
        % static functions that are defined in a separate file.
        dockerImage = localImage();
        setParams();
        [dockerExists, status, result] = exists();  % Like piDockerExists
        
        % Default servers
        function useServer = vistalabDefaultServer()
            useServer = 'muxreconrt.stanford.edu';
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

        % for now we want containers to be global, so we hacked this
        % in because Matlab doesn't support static @ class level
        % and so we can switch to making them per instance if wanted.
        % ??
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

        % Can we use fullfile and fileparts instead of requiring this?
        function output = pathToLinux(inputPath)

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
            %

            verbose = getpref('docker','verbosity',1);
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
            if ~legacyImages %contains(useImage, 'shared')
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
            end
            mountData = strrep(mountData,'//','/');
            % is our mount point always the same?
            mountPoint = obj.relativeScenePath;
            %mountPoint = dockerWrapper.pathToLinux(mountData);

            volumeMap = sprintf("-v %s:%s", mountData, mountPoint);
            placeholderCommand = 'bash';

            % set up the baseline command
            if isempty(dockerWrapper.staticVar('get','renderContext'))
                contextFlag = '';
            else
                contextFlag = [' --context ' dockerWrapper.staticVar('get','renderContext')];
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
                fprintf("Started Docker with %d: %s\n", status, cmd);
            end
            if status == 0
                obj.dockerContainerID = result; % hex name for it
                return;
            else
                warning("Failed to start Docker container with message: %s", result);
            end
        end


        function containerName = getContainer(obj,containerType)
            % I don't understand this.  More comments (BW).

            % persistent containerPBRTGPU;
            %persistent containerPBRTCPU;
            switch containerType
                case 'PBRT-GPU'
                    if isempty(obj.staticVar('get', 'PBRT-GPU', ''))
                        %containerPBRTGPU = obj.startPBRT('GPU');
                        obj.staticVar('set','PBRT-GPU', obj.startPBRT('GPU'));
                    end
                    % Need to switch to render context here!
                    if ~isempty(dockerWrapper.staticVar('get','renderContext'))
                        cFlag = ['--context ' dockerWrapper.staticVar('get','renderContext')];
                    else
                        cFlag = '';
                    end
                    [~, result] = system(sprintf("docker %s ps | grep %s", cFlag, obj.staticVar('get','PBRT-GPU', '')));
                    if strlength(result) == 0 % doesn't exist, so start one
                        obj.staticVar('set','PBRT-GPU', obj.startPBRT('GPU'));
                    end
                    containerName = obj.staticVar('get','PBRT-GPU', '');
                case 'PBRT-CPU'
                    if isempty(obj.staticVar('get', 'PBRT-CPU', ''))
                        %containerPBRTCPU = obj.startPBRT('CPU');
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
            % The remote image should already be set in most cases of
            % running remotely. If we are running locally, we ask the
            % NVidia method to give us some local options.  Mostly
            % there won't be any.

            % if we are told to run on a remote machine with a
            % particular image, that takes precedence.
            if ~isempty(obj.remoteImage)
                dockerImageName = obj.remoteImage;
                return;
            else
                disp('No remote image defined.  Assuming we should run locally.')
            end            

            % otherwise we are local and will look for the correct
            % container
            if isequal(processorType, 'GPU')

                % Check whether GPU is available
                [GPUCheck, GPUModel] = system(sprintf('nvidia-smi --query-gpu=name --format=csv,noheader -i %d',obj.whichGPU));
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
                            warning('No compatible docker image for GPU model: %s, will run on CPU', GPUModel);
                            dockerImageName = dockerWrapper.localImage();
                            %dockerContainerName = '';
                    end

                else
                    % Might be error conditions.
                    dockerImageName = '';
                end
            else
                
                dockerImageName = obj.dockerImageName;
            end
        end

        function output = convertPathsInFile(obj, input)
            % for depth or other files that have embedded "wrong" paths
            % implemented someplace, need to find the code!
        end

        %% Moved in from getRenderer
        function getRenderer(thisD)
            %GETRENDERER Creates a dockerWrapper with the user's preferences.
            %
            % Description
            %  The initial dockerWrapper is filled in with the user's preferences
            %  from (getpref('docker')).  This method builds on those to set a few
            %  additional parameters that are site-specific.
            %
            %  VISTALAB:
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
            % Beluga (not supported by this wrapper yet
            %
            % See also
            %   dockerWrapper

            % Sometimes we want to force a local machine
            % This doesn't actually work yet:(
            % forceLocal = getpref('docker','forceLocal', false);

            if thisD.localRender
                % Running locally whether there is a GPU or not
                % This is probably not yet correct (BW).
                % But nothing to be done with the remote stuff if we are running
                % locally.
                return;                

            else
                % Rendering on a remote GPU
                % This sets dockerWrapper parameters that were not already set.
                % It appears to create the context, too.                

                % Docker doesn't allow use of ~ in volume mounts, so we need to
                % make sure we know the correct remote home dir:
                if ispc
                    thisD.remoteRoot = getpref('docker','remoteRoot',getUserName(thisD));
                else
                    % No longer needed.
                    % thisD.remoteRoot = getpref('docker','remoteRoot',expanduser('~'));
                end

                if isempty(thisD.remoteMachine)
                    % The remoteMachine should be probably be set in prefs.  The
                    % user may have multiple opportunities for this.  For now we
                    % default to the vistalabDefaultServer.
                    thisD.remoteMachine = vistalabDefaultServer();
                end

                if isempty(thisD.remoteImage)
                    % If we know the remote machine, but not the remote image, at
                    % Vistalab we can fill in the remote Docker image to use.  We
                    % do this depending on the machine and the GPU.  A different
                    % image is needed for each, sigh.
                    %
                    % We should probably catch
                    if isequal(thisD.remoteMachine, vistalabDefaultServer)
                        % Right now we only allow one remote render context
                        thisD.staticVar('set','renderContext', getRenderContext(thisD, vistalabDefaultServer));
                        switch thisD.whichGPU
                            case {0, -1}
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-ampere-mux-shared';
                            case 1
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                            case 2
                                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                        end

                        % If the user specified a different tag for the docker
                        % image, use the one they specified.
                        if ~isempty(thisD.remoteImage) && ~contains(thisD.remoteImage,':') % add tag
                            thisD.remoteImage = [thisD.remoteImage, ':', thisD.remoteImageTag];
                        end
                    else
                        % This seems like a problem to me (BW).
                        warning('Not able to identify the remoteImage');
                    end
                end
            end

        end
        
        function userName = getUserName(obj)
            % Reads the user name from a docker wrapper object, or from the system and
            % then sets it in the docker wrapper object.

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



        
        function useContext = getRenderContext(dockerTemplate, serverName)
            % Get or set-up the rendering context for the docker container
            %
            % A docker context ('docker context create ...') is a set of
            % parameters we define to address the remote docker container from our
            % local computer.
            %

            switch serverName
                case 'muxreconrt.stanford.edu'
                    % Check that the Docker context exists.
                    checkContext = sprintf('docker context list');
                    [status, result] = system(checkContext);

                    if status ~= 0 || ~contains(result,'remote-mux')
                        % If we do not have it, create it
                        % e.g. ssh://david@muxreconrt.stanford.edu
                        contextString = sprintf(' --docker host=ssh://%s@%s',...
                            getUserName(dockerTemplate), vistalabDefaultServer);
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



