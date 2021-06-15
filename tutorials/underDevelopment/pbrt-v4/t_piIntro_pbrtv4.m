%% pbrt v4 introduction 
% CPU only
% using local compiled pbrt

%%
%{
./pbrt --toply /Users/zhenyi/git_repo/dev/iset3d-v4/data/V4/colorChecker/colorChecker.pbrt > /Users/zhenyi/git_repo/dev/iset3d-v4/local/formatted/colorChecker/colorChecker.pbrt
%}
ieInit;
%%
sceneName = 'testV4';
% formatted_fname = '/Users/zhenyi/git_repo/dev/iset3d/local/formatted/teapot-set/TeaTime.pbrt';
formatted_fname = '/Users/zhenyi/git_repo/dev/iset3d-v4/data/V4/colorChecker/colorChecker.pbrt';

% Read the reformatted car recipe
thisR = piRead(formatted_fname);

thisR.set('film resolution',[512 512]);
%% set render type
thisR.film.saveRadiance.type = 'bool';
thisR.film.saveRadiance.value  = true;

thisR.film.savePosition.type = 'bool';
thisR.film.savePosition.value  = false;

% thisR.film.saveRadianceasBasis.type = 'bool';
% thisR.film.savebasis.value  = false;
%% write the data out
piWrite(thisR);
%% render the scene (modify piRender later)
outputDir  = thisR.get('output dir');
currDir    = pwd;
cd(outputDir);
pbrtEXE    = '/Users/zhenyi/git_repo/PBRT_code/pbrt_zhenyi/pbrt_gpu/pbrt-v4/build/pbrt';
outputFile = fullfile(outputDir, [sceneName,'.exr']);
renderCmd  = [pbrtEXE, ' ',thisR.outputFile,' --outfile ',outputFile];
system(renderCmd)
cd(pwd);
%% read data
wave     = 400:10:700;
energy   = piReadEXR(outputFile);
photons  = Energy2Quanta(wave,energy);
ieObject = piSceneCreate(photons,'wavelength', wave);
sceneWindow(ieObject);

% get depth
depth   = piReadEXR(outputFile,'data type','zdepth');
figure;imagesc(depth);colorbar;
