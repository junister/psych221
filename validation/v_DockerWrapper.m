function success = v_DockerWrapper()
% Validate our docker Wrapper

try
    % Simplest case piWRS/piRender create a docker wrapper as needed
    % First, clear out any that exist
    ieInit();
    dockerWrapper.reset();
    ourDocker = dockerWrapper();
    sampleScene = piRecipeDefault('scene name','chess set');
    piWRS(sampleScene, 'our docker', ourDocker);
    
    fprintf('Docker wrapper Default Case succeeded\n');

    % test local rendering
    ourDocker = dockerWrapper('localRender',true);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('Docker wrapper Local Case succeeded\n');

    % test remote CPU rendering
    ourDocker = dockerWrapper('gpuRendering', false);
    piWRS(sampleScene,'our docker', ourDocker);

    fprintf('Docker wrapper CPU Case succeeded\n');
    disp('Docker wrapper validation succeeded\n');
    success = 0;
catch
    warning("Docker Wrapper validation failed.\n");
    success = -1;
end
end
