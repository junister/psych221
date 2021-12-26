function data = piEXR2Mat(infile, channelname)

[indir, fname,~] = fileparts(infile);

dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
basecmd = 'docker run -ti --volume="%s":"%s" %s %s';

cmd = ['imgtool convert --exr2bin ',channelname, ' ', infile];

if ~ispc
    dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
    [status,result] = system(dockercmd);
else
    ourDocker = dockerWrapper();
    ourDocker.command = ['imgtool convert --exr2bin ' channelname];
    ourDocker.dockerImageName = dockerimage;
    ourDocker.localVolumePath = indir;
    ourDocker.targetVolumePath = indir;
    ourDocker.inputFile = infile;
    ourDocker.outputFile = ''; % imgtool uses a default
    ourDocker.outputFilePrefix = '';
    
    [status, result] = ourDocker.runCommand();
end

if status
    disp(result);
    error('EXR to Binary conversion failed.')
end
filelist = dir([indir,sprintf('/%s_*',fname)]);

% if there are both depth and radiance files
% (on Windows at least) the Radiance files aren't
% always listed first, so we need to find one to
% get our base name
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

if strcmp(channelname,'Radiance')

    for ii = 1:31
        filename = fullfile(indir, [baseName{1},sprintf('.C%02d',ii)]);

        % On windows suffix might not exist?
        if ~isfile(filename)
            filename = fullfile(indir, baseName{1});
        end
        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        data(:,:,ii) = reshape(serializedImage, height, width, 1);
        fclose(fid);
        delete(filename);
    end
else
        filename = fullfile(indir, baseName{1});
        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        data = reshape(serializedImage, height, width, 1);
        fclose(fid);
        delete(filename);
end
    
end