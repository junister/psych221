function data = piEXR2Mat(inputFile, channelname)
% Read exr channel data into MATLAB, docker image is needed.
%
%           data = piEXR2Mat(inputFile, channelname)
%
% Brief description:
%   We take an exr file from pbrt as input and return MAT file with
%   specific channel name.
%
% Inputs
%   inputFile - Multi-spectral exr-file rendered by pbrt.
%
% Output
%   data - Matlab data.
%
%
% Zhenyi, 2021
% dockerWrapper Support, D. Cardinal, 2022
%
%%
persistent imgDocker;
[indir, fname,~] = fileparts(inputFile);

dockerimage = dockerWrapper.localImage();


if ~ispc
    basecmd = 'docker --context default run -ti --volume="%s":"%s" %s %s';
    cmd = ['imgtool convert --exr2bin ',channelname, ' ', inputFile];
    dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
    [status,result] = system(dockercmd);
else
    basecmd = 'docker --context default run -i --volume="%s":"%s" %s %s';
    cmd = ['imgtool convert --exr2bin ',channelname, ' ', dockerWrapper.pathToLinux(inputFile)];
    dockercmd = sprintf(basecmd, indir, dockerWrapper.pathToLinux(indir), dockerimage, cmd);
    [status,result] = system(dockercmd);
end
    % This seems overly complex. See if I can simplify...
    %{
    % create a new docker container for imgtool if needed
    if isempty(imgDocker), imgDocker = dockerWrapper('command',  ['imgtool convert --exr2bin ', channelname, ' ', dockerWrapper.pathToLinux(inputFile) ], ...
        'dockerImageName', dockerimage, 'localVolumePath', indir, 'targetVolumePath', indir, ...
        'inputFile', inputFile, 'outputFile', '', 'localRender', true);
    else
        % Do we need to change Volumepaths here? I would think they'd have
        % to be the same if they are the mount points (djc)
        imgDocker.inputFile = inputFile;
        imgDocker.command = ['imgtool convert --exr2bin ', channelname, ' ', dockerWrapper.pathToLinux(inputFile) ];

    end
    if getpref('docker','verbosity', 1) > 0
        stdout = '';
    else
        stdout = ' > /dev/null ';
    end
    [status, result] = imgDocker.runCommand();
end
    %}

if status
    disp(result);
    error('EXR to Binary conversion failed.')
end
allFiles = dir([indir,sprintf('/%s_*',fname)]);
fileList = [];

% In an error case there might be additional files
% This code is designed to help with that if needed
baseName = '';
height = 0;
width = 0;

for ii = 1:numel(allFiles)
    if ~isempty(strfind(allFiles(ii).name, channelname))
        dataFile = allFiles(ii);
        if isequal(baseName, '')
            baseName = strsplit(dataFile.name,'.');
        end
        nameparts = strsplit(dataFile.name,'_');
        Nparts = numel(nameparts);
        if height == 0, height = str2double(nameparts{Nparts-2}); end
        if width == 0, width= str2double(nameparts{Nparts-1}); end
        if isempty(fileList), fileList = [dataFile];
        else
            fileList(end+1) = dataFile;
        end
    end
end


if strcmp(channelname,'Radiance')

    for ii = 1:numel(fileList)
        filename = fullfile(fileList(ii).folder, fileList(ii).name);

        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        try
            data(:,:,ii) = reshape(serializedImage, height, width, 1);
        catch
            warning('Error reshaping radiance data.');
        end
        fclose(fid);
        % these channel files sometimes seem to be protected?
        delete(filename);
    end
else
    filename = fullfile(fileList(1).folder, fileList(1).name);
    [fid, message] = fopen(filename, 'r');
    serializedImage = fread(fid, inf, 'float');
    data = reshape(serializedImage, height, width, 1);
    fclose(fid);
    delete(filename);
end

end
