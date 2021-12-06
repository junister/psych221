function [status, result] = render(obj, renderCommand, outputFolder)

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

% ASSUME that if we supply a context it is on a Linux server
nativeFolder = outputFolder;
if ~isempty(obj.renderContext)
    useContext = obj.renderContext;
    outputFolder = dockerWrapper.pathToLinux(outputFolder);
else
    useContext = 'default';
end
        
% sync data over
if ~isempty(obj.remoteMachine)
    if ispc
        rSync = 'wsl rsync';
        pingC = 'wsl ping -c 1';
        % hack because wsl rsync uses Ubuntu file system!
        % Need to sort out how to make this flexible
        nativeFolder = [obj.localRoot outputFolder '/'];
    else
        rSync = 'rsync';
        pingC = 'ping -c 1';
    end
    if isempty(obj.remoteRoot)
        % if no remote root, then we need to look up our local root and use it!
    end
    if ~isempty(obj.remoteUser)
        remoteAddress = [obj.remoteUser '@' obj.remoteMachine];
    else
        remoteAddress = obj.remoteMachine;
    end
    remoteScenePath = [obj.remoteRoot outputFolder];
    remoteScene = [remoteAddress ':' remoteScenePath '/'];

    % DNS can be too slow for rsync sometimes
    % so we pre-load the A record by using ping
    %[pStatus, pResult] = system([pingC ' ' obj.remoteMachine]);
    %if pStatus ~= 0
        %warning(pResult);
    %end
    % use -c for checksum as clocks & file times won't match
    % using -z for compression, but doesn't seem to make a difference?
    [rStatus, rResult] = system(sprintf('%s -r -t %s %s',rSync, nativeFolder, remoteScene));
    if rStatus ~= 0
        error(rResult);
    end
end
containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && %s"',useContext, flags, useContainer, outputFolder, renderCommand);
[status, result] = system(containerRender);
if status == 0 && ~isempty(obj.remoteMachine)
    % sync data back
    % try just using the renderings sub-folder
    system(sprintf('%s -r %s %s',rSync, ...
        [remoteScene 'renderings/'], [nativeFolder 'renderings/']));
        %remoteScene, nativeFolder));
end
end