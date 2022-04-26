function [status, result] = render(obj, renderCommand, outputFolder)
% Render using the dockerWrapper method
%
% obj - a dockerWrapper
%
% See also
%  piRender

%%
verbose = getpref('docker','verbosity',1); % 0, 1, 2

% Currently we have an issue where GPU rendering ignores objects
% that have ActiveTranforms. Maybe scan for those & set container back
% to CPU (perhaps ideally a beefy, remote, CPU).
if obj.gpuRendering == true
    useContainer = obj.getContainer('PBRT-GPU');
    % okay this is sort of a hack
    renderCommand = strrep(renderCommand, 'pbrt ', 'pbrt --gpu ');
else
    useContainer = obj.getContainer('PBRT-CPU');
end

% Windows doesn't seem to like the t flag
if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

% ASSUME that if we supply a context it is on a Linux server
nativeFolder = outputFolder;
if ~isempty(dockerWrapper.staticVar('get','renderContext',''))
    useContext = dockerWrapper.staticVar('get','renderContext','');
else
    useContext = 'default';
end
% container is Linux, so convert
outputFolder = dockerWrapper.pathToLinux(outputFolder);

% sync data over
if ~isempty(obj.remoteMachine) && ~getpref('docker','localRender')
    % There is a remote machine
    if ispc
        rSync = 'wsl rsync';
        nativeFolder = [obj.localRoot outputFolder '/'];
    else
        rSync = 'rsync';
    end
    if isempty(obj.remoteRoot)
        obj.remoteRoot = '~';
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
    if ismac || isunix
        % We needed the extra slash for the mac.  But still investigation
        % (DJC)
        putCommand = sprintf('%s -r -t %s %s',rSync, [nativeFolder,'/'], remoteScene);
    else
        putCommand = sprintf('%s -r -t %s %s',rSync, nativeFolder, remoteScene);
    end

    if verbose > 0
        fprintf(" Rsync Put: %s\n", putCommand);
    end
    [rStatus, rResult] = system(putCommand);

    if verbose > 0
        fprintf('Pushed scene to remote in: %6.2f\n', toc(putData))
    end
    if rStatus ~= 0
        error(rResult);
    end
    renderStart = tic;
    % our output folder path starts from root, not from where the volume is
    % mounted

    shortOut = [obj.relativeScenePath sceneDir];
    % need to cd to our scene, and remove all old renders
    % some leftover files can start with "." so need to get them also
    containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && rm -rf renderings/{*,.*}  && %s"',...
        useContext, flags, useContainer, shortOut, renderCommand);
    if verbose > 0
        fprintf("Render: %s\n", containerRender);
    end

    % This is dorky. My bad:)
    if verbose > 1
        [status, result] = system(containerRender, '-echo');
        fprintf('Rendered remotely in: %6.2f\n', toc(renderStart))
        fprintf(" With Result: %s", result);
    elseif verbose == 1
        [status, result] = system(containerRender);
        if status == 0
            fprintf('Successfuly rendered remotely in: %6.2f\n', toc(renderStart))
        else
            fprintf("Error Rendering: %s", result);
        end
    else
        [status, result] = system(containerRender);
    end
    if status == 0 && ~isempty(obj.remoteMachine)

        % sync data back -- renderings sub-folder
        % This assumes that all output is in that folder!
        getOutput = tic;
        pullCommand = sprintf('%s -r %s %s',rSync, ...
            [remoteScene 'renderings/'], dockerWrapper.pathToLinux(fullfile(nativeFolder, 'renderings')));
        if verbose > 0
            fprintf(" Rsync Pull: %s\n", pullCommand);
        end

        % bring back results
        system(pullCommand);
        if verbose > 0
            fprintf('Retrieved output in: %6.2f\n', toc(getOutput))
        end
    end
else
    % our output folder path starts from root, not from where the volume is
    % mounted -- sort of weenie as this is the Windows path while on
    % windows
    % {
       dockerCommand = 'docker run -ti --rm';
       if ~isempty(outputFolder)
            if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
            dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, outputFolder);
        end
        dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, outputFolder, outputFolder);       
        containerRender = sprintf('%s %s %s', dockerCommand, obj.dockerImageName, renderCommand);
    %}
    %{
    shortOut = fullfile(obj.relativeScenePath,sceneDir);
    containerRender = sprintf('docker exec %s %s sh -c "cd %s && %s"', flags, useContainer, shortOut, renderCommand);
    %}
    renderStart = tic;
    [status, result] = system(containerRender);
    if verbose > 0
        fprintf('Rendered locally in: %6.2f\n', toc(renderStart))
    end
end

end

