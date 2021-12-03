function [status, result] = render(obj, renderCommand, outputFolder)

if obj.gpuRendering == true
    useContainer = obj.getContainer('PBRT-GPU');
    % okay this is a hack!
    renderCommand = replaceBetween(renderCommand, 1,4, 'pbrt --gpu ');
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
        % hack because wsl rsync uses Ubuntu file system!
        nativeFolder = ['/mnt/c' outputFolder '/'];
    else
        rSync = 'rsync';
    end
    if isempty(obj.remoteRoot)
        % if no remote root, then we need to look up our local root and use it!
    end
    remoteScenePath = [obj.remoteRoot outputFolder];
    remoteScene = [obj.remoteMachine ':' remoteScenePath '/'];
    system(sprintf('%s -r %s %s',rSync, nativeFolder, remoteScene));
end
containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && %s"',useContext, flags, useContainer, outputFolder, renderCommand);
[status, result] = system(containerRender);
if status == 0 && ~isempty(obj.remoteMachine)
    % sync data back
    system(sprintf('%s -r %s %s',rSync, remoteScene, nativeFolder));
end
end