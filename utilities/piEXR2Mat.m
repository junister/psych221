function data = piEXR2Mat(infile, channelname)

[indir, fname,~] = fileparts(infile);

dockerimage = 'camerasimulation/pbrt-v4-cpu';
basecmd = 'docker run -ti --volume="%s":"%s" %s %s';

cmd = ['imgtool convert --exr2bin ',channelname, ' ', infile];

if ~ispc
    dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
    [status,result] = system(dockercmd);
else
    ourDocker = docker();
    ourDocker.command = ['imgtool convert --exr2bin ' channelname];
    ourDocker.containerName = dockerimage;
    ourDocker.localVolumePath = indir;
    ourDocker.targetVolumePath = indir;
    ourDocker.inputFile = infile;
    ourDocker.outputFile = ''; % imgtool uses a default

    status = ourDocker.run();
end

if status
    disp(result);
    error('EXR to Binary conversion failed.')
end
filelist = dir([indir,sprintf('/%s_*',fname)]);
nameparts = strsplit(filelist(1).name,'_');
Nparts = numel(nameparts);
height = str2double(nameparts{Nparts-2});
width= str2double(nameparts{Nparts-1});

if strcmp(channelname,'Radiance')
    baseName = strsplit(filelist(1).name,'.');
    for ii = 1:31
        filename = fullfile(indir, [baseName{1},sprintf('.C%02d',ii)]);
        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        data(:,:,ii) = reshape(serializedImage, height, width, 1);
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