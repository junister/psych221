% v_DockerWrapper()
%
% Validate various docker Wrapper calls
%
% Assumes that 'docker' prefs are set for
% 
%    Variables            Stanford Defaults
%   ---------------       -----------------
%   remoteMachine         muxreconrt.stanford.edu
%   remoteImage           digitalprodev/XXX
%   renderContext         remote-mux
%

%% Initialize as usual
ieInit();
if ~piDockerExists, piDockerConfig; end

%% Default rendering

fprintf('*** User defaults ... ****\n');
fprintf('-------------------------------------\n\n')

try
    % Simplest case piWRS/piRender create a docker wrapper as needed
    % First, clear out any that exist
    dockerWrapper.reset();
    sampleScene = piRecipeDefault('scene name','chess set');
    piWRS(sampleScene);

    fprintf('succeeded.\n');
    fprintf('-------------------------------------\n')
catch
    fprintf('failed.\n');
    fprintf('-------------------------------------\n')
end

%% Default rendering, verbose
fprintf('*** User default verbose ... ***\n');
fprintf('-------------------------------------\n\n')

try
    dockerWrapper.reset;
    ourDocker = dockerWrapper('verbosity',2);
    piWRS(sampleScene, 'our docker', ourDocker);
    
    fprintf('succeeded\n');
    fprintf('-------------------------------------\n')
catch
    fprintf('failed\n');
    fprintf('-------------------------------------\n')

end

%% Local rendering CPU

fprintf('*** Local render on CPU ... ***');
fprintf('-------------------------------------\n\n')

try
    % test local rendering on CPU
    % need to turn off GPU rendering or we've given it conflicting
    % instructions in the case where the GPU is remote
    ourDocker = dockerWrapper('localRender',true,'gpuRendering', false,'verbosity',2);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('succeeded\n');
    fprintf('-------------------------------------\n')

catch
    fprintf(' failed\n');
    fprintf('-------------------------------------\n')
end

%% Remote rendering (mux) CPU

fprintf('*** Remote rendering on CPU ... ***\n');
fprintf('-------------------------------------\n\n')
try
    % test remote CPU rendering
    % currenctly we keep a cache of 1 GPU and 1 CPU container
    % so creating a second one of either requires a reset
    dockerWrapper.reset();

    % NOTE: To render remotely, we may need to specify the .remoteImage
    %       since we don't know what CPU it is
    x86Image = 'digitalprodev/pbrt-v4-cpu:latest';
    ourDocker = dockerWrapper('gpuRendering', false,...
        'remoteImage',x86Image, 'verbosity',2);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('succeeded\n');
    fprintf('-------------------------------------\n')
catch
    fprintf(' failed\n');
    fprintf('-------------------------------------\n')
end

%% END
