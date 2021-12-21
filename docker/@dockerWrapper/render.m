function [status, result] = render(obj, renderCommand, outputFolder)

verbose = true;

if obj.gpuRendering == true
    useContainer = obj.getContainer('PBRT-GPU');
    % okay this is a hack!
    renderCommand = strrep(renderCommand, 'pbrt ', 'pbrt --gpu ');
else
    useContainer = obj.getContainer('PBRT-CPU');
end

% Windows doesn't seem to like the t flag
if ispc
    flags = '-i ';
else
    flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

% ASSUME that if we supply a context it is on a Linux server
nativeFolder = outputFolder;
if ~isempty(obj.renderContext)
    useContext = obj.renderContext;
else
    useContext = 'default';
end
% container is Linux, so convert
outputFolder = dockerWrapper.pathToLinux(outputFolder);
        
% sync data over
if ~isempty(obj.remoteMachine)
    if ispc
        rSync = 'wsl rsync';
        nativeFolder = [obj.localRoot outputFolder '/'];
    else
        rSync = 'rsync';
    end
    if isempty(obj.remoteRoot)
        % if no remote root, then we need to look up our local root and use it!
    end
    if ~isempty(obj.remoteUser)
        remoteAddress = [obj.remoteUser '@' obj.remoteMachine];
    else
        remoteAddress = obj.remoteMachine;
    end

    % in the case of Mac (& Linux?) outputFolder includes both
    % our iset dir and then the relative path
    [~, sceneDir, ~] = fileparts(outputFolder);
    remoteScenePath = [obj.remoteRoot obj.relativeScenePath sceneDir];

    %remoteScenePath = [obj.remoteRoot outputFolder];
    remoteScenePath = strrep(remoteScenePath, '//', '/');
    remoteScene = [remoteAddress ':' remoteScenePath '/'];

    % use -c for checksum if clocks & file times won't match
    % using -z for compression, but doesn't seem to make a difference?
    putData = tic;
    if ismac
        % We needed the extra slash for the mac.  But still investigation
        % (DJC)
        putCommand = sprintf('%s -r -t %s %s',rSync, [nativeFolder,'/'], remoteScene);
    else
        putCommand = sprintf('%s -r -t %s %s',rSync, nativeFolder, remoteScene);
    end
    
    if verbose
        fprintf(" Rsync Put: %s\n", putCommand);
    end
    [rStatus, rResult] = system(putCommand);

    if verbose
        fprintf('Pushed scene to remote in: %6.2f\n', toc(putData))
    end
    if rStatus ~= 0
        error(rResult);
    end
    renderStart = tic;
    % our output folder path starts from root, not from where the volume is
    % mounted

    shortOut = [obj.relativeScenePath sceneDir];
    containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && rm -rf renderings/* && %s"',useContext, flags, useContainer, shortOut, renderCommand);
    % containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && %s"',useContext, flags, useContainer, remoteScenePath, renderCommand);
    if verbose
        fprintf("Render: %s\n", containerRender);
    end
    [status, result] = system(containerRender);
    if true % verbose
        fprintf('Rendered remotely in: %6.2f\n', toc(renderStart))
        fprintf(" With Result: %s", result);
    end
    if status == 0 && ~isempty(obj.remoteMachine)
    % sync data back
    % try just using the renderings sub-folder
    getOutput = tic;
    pullCommand = sprintf('%s -r %s %s',rSync, ...
        [remoteScene 'renderings/'], dockerWrapper.pathToLinux(fullfile(nativeFolder, 'renderings')));
    if verbose
        fprintf(" Rsync Pull: %s\n", pullCommand);
    end

    % bring back results
    system(pullCommand);
    if verbose
        fprintf('Retrieved output in: %6.2f\n', toc(getOutput))
    end
    end
else
    % our output folder path starts from root, not from where the volume is
    % mounted -- sort of weenie as this is the Windows path while on
    % windows
    shortOut = [obj.relativeScenePath sceneDir];
    containerRender = sprintf('docker exec %s %s sh -c "cd %s && %s"', flags, useContainer, shortOut, renderCommand);
    renderStart = tic;
    [status, result] = system(containerRender);
    if verbose
        fprintf('Rendered using default in: %6.2f\n', toc(renderStart))
    end
end
end