%% pbrt v4 introduction 
% CPU only
% using local compiled pbrt

%%
%{
./pbrt --toply /Users/zhenyi/git_repo/dev/iset3d/data/V4/teapot-set/TeaTime.pbrt > /Users/zhenyi/git_repo/dev/iset3d/local/formatted/teapot-set/TeaTime.pbrt
%}

sceneName = 'TeaTime';
formatted_fname = '/Users/zhenyi/git_repo/dev/iset3d/local/formatted/teapot-set/TeaTime.pbrt';

% Read the reformatted car recipe
recipeV4 = piRead(formatted_fname);

recipeV4.set('film resolution',[512 512]);

recipeV4.film.subtype = 'gbuffer';

recipeV4.film.saveRadiance.type = 'bool';
recipeV4.film.saveRadiance.value  = true;

recipeV4.film.savePosition.type = 'bool';
recipeV4.film.savePosition.value  = true;

piWrite(recipeV4);

pbrtEXE   = '/Users/zhenyi/git_repo/PBRT_code/pbrt_zhenyi/pbrt_gpu/pbrt-v4/build/pbrt';
outputDir = recipeV4.get('output dir');
outputFile = fullfile(outputDir, [sceneName,'.exr']);
renderCmd = [pbrtEXE, ' ',recipeV4.outputFile,' --outfile ',outputFile];
system(renderCmd)
%% read data
wave     = 400:10:700;

energy   = piReadEXR(outputFile);
photons  = Energy2Quanta(wave,energy);
ieObject = piSceneCreate(photons,'wavelength', wave);
sceneWindow(ieObject);

% get depth
depth   = piReadEXR(outputFile,'data type','zdepth');
figure;imagesc(depth);colorbar;
