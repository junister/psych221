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

[dir, fname,~] = fileparts(infile);
outfile = fullfile(dir, [fname,'-converted.pbrt']);
currdir = pwd;
cd(dir);

%% Runs assimp command
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
cmd = [[assimpBinary ' export '],infile, ' ',[fname,'-converted.pbrt']];
[status,result] = system(cmd);

if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end

cd(currdir);

end