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
formatted_fname = '/Users/zhenyi/git_repo/dev/iset3d/local/formatted/teapot-set/TeaTime.pbrt';
% formatted_fname = '/Users/zhenyi/git_repo/dev/iset3d-v4/data/V4/colorChecker/colorChecker.pbrt';

% Read the reformatted car recipe
thisR = piRead(formatted_fname);

thisR.set('film resolution',[256 256]);
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
pbrtPath    = '/Users/zhenyi/git_repo/PBRT_code/pbrt_zhenyi/pbrt_gpu/pbrt-v4/build/pbrt';
scene = piRender_local(thisR, pbrtPath);
sceneWindow(scene);
