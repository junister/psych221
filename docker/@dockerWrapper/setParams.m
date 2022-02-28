function  setParams(options)
%SETDocker set Docker rendering options

arguments
    options.whichGPU {mustBeNumeric} = 0;
    options.gpuRendering = '';

    % these relate to remote/server rendering
    % they overlap while we learn the best way to organize them
    options.remoteMachine = ''; % for syncing the data
    options.remoteUser = ''; % use for rsync & ssh/docker

    options.remoteImage = '';
    options.remoteImageTag = '';
    options.remoteRoot = ''; % we need to know where to map on the remote system
    options.localRoot = ''; % for the Windows/wsl case (sigh)

end
setpref('docker','whichGPU', options.whichGPU);

if isnumeric(options.gpuRendering)
    setpref('docker','gpuRendering', options.gpuRendering);
end
if ~isempty(options.remoteUser)
    setpref('docker', 'remoteUser', options.remoteUser);
end
if ~isempty(options.remoteImage)
    setpref('docker', 'remoteImage', options.remoteImage);
end
if ~isempty(options.remoteImageTag)
    setpref('docker', 'remoteImageTag', options.remoteImageTag);
end
if ~isempty(options.remoteRoot)
    setpref('docker', 'remoteRoot', options.remoteRoot);
end
if ~isempty(options.localRoot)
    setpref('docker', 'localRoot', options.localRoot);
end

dockerWrapper.reset;
end

