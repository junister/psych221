%% Test Krithin's table

sceneDir = 'table';
sceneFile = 'Table-pbrt.pbrt';
exporter = 'PARSE';

FilePath = fullfile(piDirGet('scenes'),sceneDir);
fname = fullfile(FilePath,sceneFile);
exist(fname,'file')

thisR = piRead(fname, 'exporter', exporter);

thisR.set('skymap','room.exr');

scene = piWRS(thisR);

%% Try the Arch

sceneDir = 'arch';
sceneFile = 'Arch3d-pbrt.pbrt';
exporter = 'PARSE';

FilePath = fullfile(piDirGet('scenes'),sceneDir);
fname = fullfile(FilePath,sceneFile);
exist(fname,'file')

thisR = piRead(fname, 'exporter', exporter);

thisR.set('skymap','room.exr');

scene = piWRS(thisR);