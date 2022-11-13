function result = v_DockerWrapper(options)
% v_DockerWrapper()
%
% Validate various docker Wrapper calls
%
% Assumes that 'docker' prefs are set for
%
%    Variables            Stanford Defaults
%   ---------------       -----------------
%   remoteMachine         <servername>.stanford.edu
%   remoteImage           digitalprodev/XXX
%   renderContext         remote-mux
%

arguments
    options.length = 'short'; % how detailed a test to run
end

%% Initialize as usual
%
% iClear = getpref('ISET','initclear');
setpref('ISET','initclear',0);
ieInit;
%    ...
%    setpref('ISET','initclear',iClear);

result = 0; % default is success.

if ~piDockerExists, piDockerConfig; end

%% Default rendering

fprintf('*** User defaults ... ****\n');
fprintf('-------------------------------------\n\n')

try
    % Simplest case piWRS/piRender create a docker wrapper as needed
    % First, clear out any that exist
    dockerWrapper.reset();
    sampleScene = piRecipeDefault('scene name','chess set');
catch
    fprintf('Unable to load sample scene.\n');
    fprintf('-------------------------------------\n')
    result = -1;
end

%% Default rendering, verbose
fprintf('*** Rendering with verbosity = 2 ***\n');
fprintf('-------------------------------------\n\n')

try
    dockerWrapper.reset;
    ourDocker = dockerWrapper('verbosity',2,'gpuRendering',1);
    piWRS(sampleScene, 'our docker', ourDocker);

    fprintf('succeeded\n');
    fprintf('-------------------------------------\n')
catch
    fprintf('Sample Scene failed\n');
    fprintf('-------------------------------------\n')
    result = -1;
end

%% Local rendering CPU

fprintf('*** Local CPU render, verbosity = 0 ... ***');
fprintf('-------------------------------------\n\n');

try
    % test local rendering on CPU
    % need to turn off GPU rendering or we've given it conflicting
    % instructions in the case where the GPU is remote
    ourDocker = dockerWrapper('localRender',true,'gpuRendering', false,'verbosity',0);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('succeeded\n');
    fprintf('-------------------------------------\n');

catch
    fprintf(' failed\n');
    fprintf('-------------------------------------\n');
    result = -1;
end

fprintf('*** Remote rendering on CPU :humanEye test... ***\n');
fprintf('-------------------------------------\n\n')
try
    % test remote CPU rendering
    % currently we cache 1 GPU and 1 CPU container
    % Initializing a second one of either requires a reset
    dockerWrapper.reset();

    % NOTE: To render remotely, we may need to specify the .remoteImage
    %       since we don't know what CPU it is
    % Remote CPU for tagged case

    thisDWrapper = dockerWrapper;
    thisDWrapper.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu:humanEye';
    thisDWrapper.remoteImageTag = 'humanEye';
    thisDWrapper.gpuRendering = 0;
    piWRS(sampleScene,'our docker', thisDWrapper);

    %{
        DJC initial test code -- works
    thisDWrapper = dockerWrapper('verbosity', 2, 'remoteCPUImage', ...
        'digitalprodev/pbrt-v4-cpu:humanEye', 'remoteImageTag', 'humanEye', ...
        'gpuRendering', 0);
    piWRS(sampleScene,'our docker', thisDWrapper);
    %}

    fprintf('succeeded\n');
    fprintf('-------------------------------------\n');

catch
    fprintf(' failed\n');
    fprintf('-------------------------------------\n');
    result = -1;
end

if isequal(options.length, 'long')
    %% Remote rendering (mux) CPU

    fprintf('*** Remote rendering on CPU ... ***\n');
    fprintf('-------------------------------------\n\n')
    try
        % test remote CPU rendering
        % currently we cache 1 GPU and 1 CPU container
        % Initializing a second one of either requires a reset
        dockerWrapper.reset();

        % NOTE: To render remotely, we may need to specify the .remoteImage
        %       since we don't know what CPU it is
        x86Image = 'digitalprodev/pbrt-v4-cpu:latest';
        ourDocker = dockerWrapper('gpuRendering', false,...
            'remoteImage',x86Image, 'verbosity',2);
        piWRS(sampleScene,'our docker', ourDocker);

        fprintf('succeeded\n');
        fprintf('-------------------------------------\n');
    catch
        fprintf(' failed\n');
        fprintf('-------------------------------------\n');
        result = -1;
    end

end

%% END
