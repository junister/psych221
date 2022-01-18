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
%%
persistent ourDocker;
[indir, fname,~] = fileparts(inputFile);

dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
basecmd = 'docker run -ti --volume="%s":"%s" %s %s';

cmd = ['imgtool convert --exr2bin ',channelname, ' ', inputFile];

if ~ispc
    dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
    [status,result] = system(dockercmd);
else

    if isempty(ourDocker), ourDocker = dockerWrapper(); end
    ourDocker.command = ['imgtool convert --exr2bin ' channelname];
    ourDocker.dockerImageName = dockerimage;
    ourDocker.localVolumePath = indir;
    ourDocker.targetVolumePath = indir;
    ourDocker.inputFile = inputFile;
    ourDocker.outputFile = ''; % imgtool uses a default
    ourDocker.outputFilePrefix = '';

    [status, result] = ourDocker.runCommand();
end

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
        height = str2double(nameparts{Nparts-2});
        width= str2double(nameparts{Nparts-1});
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
            pause;
        end
        fclose(fid);
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