function success = v_DockerWrapper()
% Validate our docker Wrapper

% Assumes that prefs are set for
% 
% remoteMachine
% remoteImage (if on an unknown server)
%
try
    % Simplest case piWRS/piRender create a docker wrapper as needed
    % First, clear out any that exist
    ieInit();
    dockerWrapper.reset();
    sampleScene = piRecipeDefault('scene name','chess set');
    piWRS(sampleScene);

    fprintf('Simple piWRS succeeded.\n');

    dockerWrapper.reset;
    ourDocker = dockerWrapper('verbosity',2);
    piWRS(sampleScene, 'our docker', ourDocker);
    
    fprintf('Docker wrapper Default Case succeeded\n');

    % test local rendering on CPU
    % need to turn off GPU rendering or we've given it conflicting
    % instructions in the case where the GPU is remote
    ourDocker = dockerWrapper('localRender',true,'gpuRendering', false,'verbosity',2);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('Docker wrapper Local Case succeeded\n');

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

    fprintf('Docker wrapper CPU Case succeeded\n');
    disp('Docker wrapper validation succeeded\n');
    success = 0;
catch
    warning("Docker Wrapper validation failed.\n");
    success = -1;
end
end
