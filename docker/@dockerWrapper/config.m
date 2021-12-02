function status = config(obj, varargin)
% Configure the Matlab environment and initiate the docker-machine
%
%   status = dockerWrapper.config(varargin)
%
% INPUTS:
%    'machine' - [Optional, type=char, default='default']
%                Name of the docker-machine on OSX. Should exist.
%    'debug'   - [Optional, type=logical, default=false]
%                If true then messages are displayed throughout the
%                process, otherwise we're quiet save for an error.
%
% OUTPUTS:
%    status    - boolean where 0=success and >0 denotes failure.
%
% EXAMPLE:
%    [status] = piDockerConfig('machine', 'default', 'debug', true);
%
% (C) Stanford VISTA Lab, 2016
%
% Remote server code added by D. Cardinal 2021
%

%% Parse input arguments

p = inputParser;
p.addParameter('machine', 'default', @ischar);
p.addOptional('debug', false, @islogical);
p.addOptional('gpuRendering', true, @islogical);
p.addOptional('renderContext', '', @ischar); % experimental
p.addOptional('remoteImage', '', @ischar); % image to use for remote render

p.parse(varargin{:})

args = p.Results;

if ~isempty(args.gpuRendering)
    obj.gpuRendering = args.gpuRendering;
end

% for remote rendering we need to be passed the docker context to use
if ~isempty(args.renderContext)
    obj.renderContext = args.renderContext;
    % since the remote system might have a different GPU
    % currently we need to have that passed in as well
    if ~isempty(args.remoteImage)
        obj.remoteImage = args.remoteImage;
    end
end


%% Configure Matlab ENV for the machine

% MAC OSX
if ismac
    
    % By default, docker-machine and docker for mac are installed in
    % /usr/local/bin:
    initPath = getenv('PATH');
    if ~piContains(initPath, '/usr/local/bin')
        if args.debug
            disp('Adding ''/usr/local/bin'' to PATH.');
        end
        setenv('PATH', ['/usr/local/bin:', initPath]);
    end
    
    % Check for "docker for mac"
    [status, ~] = system('docker ps -a');
    if status == 0
        if args.debug
            disp('Docker configured successfully!');
            system('which docker', '-echo');
        end
        return
    elseif exist('/Applications/Docker.app/Contents/MacOS/Docker', 'file')
        if args.debug
            disp('Starting Docker for Mac...')
        end
        [s, ~] = system('open /Applications/Docker.app');
        [status, ~] = system('which docker', '-echo');
        if s==0 && status==0
            if args.debug
                disp('Docker configured successfully!');
                system('docker -v', '-echo');
            end
        end
        return
    end
    
    % Check that docker machine is installed
    [status, version] = system('docker-machine -v');
    if status == 0
        if args.debug
            fprintf('Found %s\n', version);
        end
    else
        error('%s \nIs docker-machine installed?', version);
    end
    
    % Check that the machine is running
    [~, result] = system(sprintf('docker-machine status %s', args.machine));
    if strcmp(strtrim(result),'Running')
        if args.debug
            fprintf('docker-machine ''%s'' is running.\n', args.machine);
        end
        
        % Start the machine
    else
        fprintf('Starting docker-machine ''%s'' ... \n', args.machine);
        [status, result] = system(sprintf('docker-machine start %s', args.machine), '-echo');
        if status && piContains(strtrim(result), 'not exist')
            
            % Prompt to create the machine
            resp = input('Would you like to create the machine now? (y/n): ', 's');
            if lower(resp) == 'y'
                [status, result] = system(sprintf('docker-machine create -d virtualbox %s', args.machine), '-echo');
                if status
                    error(result);
                else
                    fprintf('The machine ''%s'' is up and running!\n', args.machine);
                end
            else
                warning(result);
                status = 1;
                return
            end
        end
    end
    
    % Get the docker env variables for the machine
    [status, docker_env] = system(sprintf('docker-machine env %s', args.machine));
    if status ~= 0; error(docker_env); end
    
    % Configure the Matlab ENV based on the machine ENV
    docker_env = strsplit(docker_env);
    docker_env_vars = {};
    for ii = 1:numel(docker_env)
        if strfind(docker_env{ii}, 'DOCKER')
            docker_env_vars{end+1} = docker_env{ii}; %#ok<AGROW>
        end
    end
    if args.debug
        fprintf('Configuring docker-machine env for machine: [%s] ...\n', args.machine);
    end
    for jj = 1:numel(docker_env_vars)
        env_var = strsplit(docker_env_vars{jj},'"');
        setenv(strrep(env_var{1},'=',''), env_var{2});
        if args.debug
            fprintf('%s=%s\n', strrep(env_var{1},'=',''), getenv(strrep(env_var{1},'=','')));
        end
    end
    
    % Check that the configuration worked
    [status, result] = system('docker ps -a');
    if status == 0
        if args.debug
            disp('Docker configured successfully!');
        end
    else
        error('Docker could not be configured: %s', result);
    end
    
    % LINUX
elseif isunix
    
    % Check for docker
    [status, result] = system('docker ps -a');
    if status == 0
        if args.debug; disp('Docker configured successfully!'); end
    else
        if (args.debug); fprintf('Docker status: %d\n',status); end
        error('Docker not configured: %s', result);
    end
elseif ispc
    % Check for docker
    [status, result] = system('docker ps -a');
    if status == 0
        if args.debug; disp('Docker configured successfully!'); end
    else
        if (args.debug); fprintf('Docker status: %d\n',status); end
        error('Docker not configured: %s', result);
    end
end

% now that we have docker ready to go, ...
