function data = piEXR2Mat(inputFile, channelname)
% Read exr channel data into MATLAB, docker image is needed.
%
%           data = piEXR2Mat(inputFile, channelname)
%
% Brief description:
%   We take an exr file from pbrt as input and return MAT file with
%   specific channel name.  Relies on the imgtool code inside our PBRT
%   docker container.
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


%tic();
[indir, fname,~] = fileparts(inputFile);
dockerimage = dockerWrapper.localImage();

needImgtool = true;
% Create a clean sub-directory for our channels
channelDir = fullfile(indir,'channels/');
if ~isfolder(channelDir)
    mkdir(channelDir); 
else
    % if the channels folder exists we have already rendered our output
    needImgtool = false;
end
outputFile = fullfile(channelDir,fname);

% Use the imgtool to convert exr data.
if needImgtool
if ispc 
    flags = '-i';
else
    flags = '-ti';
end
basecmd = 'docker --context default run %s --volume="%s":"%s" %s %s';
% for per-channel retrieval
%cmd = ['imgtool convert --exr2bin ',channelname, ' ', inputFile];
cmd = ['imgtool convert --exr2bin --outfile ',dockerWrapper.pathToLinux(outputFile), ' ', dockerWrapper.pathToLinux(inputFile)];
dockercmd = sprintf(basecmd, flags, indir, dockerWrapper.pathToLinux(indir), dockerimage, cmd);
[status,result] = system(dockercmd);

%fprintf('piEXR2Mat imgtool: %s\n',toc());

if status
    disp(result);
    error('EXR to Binary conversion failed.')
end

end

% only retrieve the files we need for this channel
allFiles = dir([channelDir,sprintf('/%s_*%s*',fname,channelname)]);

%{
% In some cases we might get R,G,B for Radiance instead of Radiance channels
% so something like this might be helpful?
if isempty(allFiles) && strcmp(channelname, 'Radiance')
    fullFiles = dir([channelDir,sprintf('%s_*',fname)]);
    allFiles(1) = fullFiles(1);
    allFiles(2) = fullFiles(2);
    allFiles(3) = fullFiles(3);
end
%}

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

        % Extract the row/col values from the file name.  This should
        % be the same for all of the radiance channels and the depth
        % image and the pixel labels.
        Nparts = numel(nameparts);
        if height == 0, height = str2double(nameparts{Nparts-2}); end
        if width  == 0, width  = str2double(nameparts{Nparts-1}); end

        if isempty(fileList)
            fileList = dataFile;
        else
            fileList(end+1) = dataFile; %#ok<AGROW>
        end
    end
end


if strcmp(channelname,'Radiance')

    % Radiance data
    data = zeros(height,width,numel(fileList));

    for ii = 1:numel(fileList)
        filename = fullfile(fileList(ii).folder, fileList(ii).name);

        fid = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        fclose(fid);
        %fprintf('piEXR2Mat Read: %s\n',toc());

        % We haven't had a warning here in a long time.  Probably safe
        % to delete the try catch that was here.
        data(:,:,ii) = reshape(serializedImage, height, width, 1);

        % these channel files sometimes seem to be protected?
        delete(filename);
    end
else
    filename = fullfile(fileList(1).folder, fileList(1).name);
    fid = fopen(filename, 'r');
    serializedImage = fread(fid, inf, 'float');
    data = reshape(serializedImage, height, width, 1);
    fclose(fid);
    delete(filename);
end
%fprintf('piEXR2Mat: %s\n',toc());

end

% This seems overly complex. See if I can simplify...
%{

   persistent imgDocker;
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
