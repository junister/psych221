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

thisR.set('film resolution',[300 300]);
thisR.set('rays per pixel',16)
%% set render type
% radiance 
% rTypes = {'radiance','irradiance','depth','both','all','coordinates','material','mesh', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})

%% write the data out
piWrite(thisR);
%% render the scene (modify piRender later)

scene = piRender(thisR);
sceneWindow(scene);
