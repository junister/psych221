function outfile = piFBX2PBRT(infile)
% convert a FBX file to PBRT file.
%
[dir, fname,~] = fileparts(infile);
outfile = fullfile(dir, [fname,'-converted.pbrt']);
currdir = pwd;
cd(dir);
cmd = ['assimp export ',infile, ' ',[fname,'-converted.pbrt']];
[status,result] = system(cmd);
if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end
cd(currdir);
end