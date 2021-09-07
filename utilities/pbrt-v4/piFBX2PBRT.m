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
% if ispc
%     assimpBinary = '"C:\Program Files (x86)\Assimp\bin\assimp"';
% else
%     assimpBinary = 'assimp';
% end
%}
% build docker base cmd

dockerimage = 'camerasimulation/pbrt-v4-cpu';

if ~ispc
    basecmd = 'docker run -ti --name %s --volume="%s":"%s" %s %s';
    
    cmd = ['assimp export ',infile, ' ',[fname,'-converted.pbrt']];
    
    dockercontainerName = ['Assimp-',num2str(randi(200))];
    dockercmd = sprintf(basecmd, dockercontainerName, indir, indir, dockerimage, cmd);
    
    [status,result] = system(dockercmd);
else 
    ourDocker = dockerWrapper();
    ourDocker.dockerFlags = '-ti'; % no -rm this time!
    ourDocker.dockerContainerName = ['Assimp' num2str(randi(200))];
    ourDocker.dockerImageName = dockerimage;
    ourDocker.command = 'assimp export';
    ourDocker.inputFile = infile;
    ourDocker.outputFile = [fname '-converted.pbrt'];
    [status, result] = ourDocker.run();    
end

if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end

cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, [fname,'-converted.pbrt'], indir);
[status_copy, ~ ] = system(cpcmd);

cd(currdir);
if status_copy
    disp(result);
    error('Copy file from docker container failed.\n ');
end

% remove docker container
rmCmd = sprintf('docker rm %s',dockercontainerName);
system(rmCmd);
end

