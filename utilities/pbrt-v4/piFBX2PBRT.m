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
cmd = ['assimp export ',infile, ' ',[fname,'-converted.pbrt']];
[status,result] = system(cmd);

if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end

cd(currdir);

end