function outfile = piFBX2PBRT(infile)
% Convert a FBX file to a PBRT file using assimp
%
% Input
%  infile (fbx)
% Key/val
%
% Output
%   outfile (pbrt)
%
% Some day we will Dockerize assimp
%
% See also
%

%% Find the input file and specify the converted output file

[indir, fname,~] = fileparts(infile);
outfile = fullfile(indir, [fname,'-converted.pbrt']);
currdir = pwd;
cd(indir);

%% Runs assimp command
%{
% Windows doesn't add assimp dir to PATH by default
% Not sure of the best way to handle that. Maybe we can even just ship the
% binaries and point to them?
if ispc
    if isfile('C:\Program Files (x86)\assimp\bin64\assimp.exe')
        assimpBinary = '"C:\Program Files (x86)\assimp\bin64\assimp.exe"';
    else
        assimpBinary = '"C:\Program Files (x86)\Assimp\bin\assimp.exe"';
    end
else
    assimpBinary = 'assimp';
end

if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end

if ~ispc
    cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, [fname,'-converted.pbrt'], indir);
    [status_copy, ~ ] = system(cpcmd);
else
    cpDocker = dockerWrapper();
    cpDocker.dockerImageName = ''; % use running container
    cpDocker.dockerCommand = 'docker cp';
    cpDocker.command = '';
    cpDocker.dockerFlags = '';
    linuxDir = cpDocker.pathToLinux(indir);
    cpDocker.inputFile = [dockercontainerName ':' linuxDir  filesep()  fname '-converted.pbrt'];
    cpDocker.outputFile = indir;
    cpDocker.outputFilePrefix = '';
    [status_copy, result] = cpDocker.run();
end
cd(currdir);
if status_copy
    disp(result);
    error('Copy file from docker container failed.\n ');
end

% remove docker container
rmCmd = sprintf('docker rm %s',dockercontainerName);
system(rmCmd);
end

