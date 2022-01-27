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
[indir, fname,~] = fileparts(inputFile);

dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
basecmd = 'docker run -ti --volume="%s":"%s" %s %s';

cmd = ['imgtool convert --exr2bin ',channelname, ' ', inputFile];

if ~ispc
    [~,username] = system('whoami');
    if strncmp(username,'zhenyi',6)
        localcmd = sprintf('/Users/zhenyi/git_repo/PBRT_code/pbrt_zhenyi/pbrt_gpu/pbrt-v4/build/%s',cmd);
        [status,result] = system(localcmd);
    else
        dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
        [status,result] = system(dockercmd);
    end
else
    ourDocker = dockerWrapper();
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
filelist = dir([indir,sprintf('/%s_*',fname)]);

%{
% In an error case there might be additional files
% This code is designed to help with that if needed
baseName = '';
dataFile = '';
for ii = 1:numel(filelist)
    if isequal(baseName, '') && ~isempty(strfind(filelist(ii).name, channelname))
        dataFile = filelist(ii);
        baseName = strsplit(filelist(ii).name,'.');
        nameparts = strsplit(filelist(ii).name,'_');
        Nparts = numel(nameparts);
        height = str2double(nameparts{Nparts-2});
        width= str2double(nameparts{Nparts-1});
    end
end
%}
nameparts = strsplit(filelist(1).name,'_');
Nparts = numel(nameparts);
height = str2double(nameparts{Nparts-2});
width= str2double(nameparts{Nparts-1});


if strcmp(channelname,'Radiance')
    baseName = strsplit(filelist(1).name,'.');

    for ii = 1:31
        filename = fullfile(indir, [baseName{1},sprintf('.C%02d',ii)]);

        % On windows suffix might not exist?
        if ~isfile(filename)
            filename = fullfile(indir, baseName{1});
        end
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
    filename = fullfile(indir, filelist(1).name);
    [fid, message] = fopen(filename, 'r');
    serializedImage = fread(fid, inf, 'float');
    data = reshape(serializedImage, height, width, 1);
    fclose(fid);
    delete(filename);
end

end