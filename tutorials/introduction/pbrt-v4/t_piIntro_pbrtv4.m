%% pbrt v4 introduction 
% CPU only
% using local compiled pbrt

%%
ieInit;
%%
sceneName = 'testV4';
fbxFile   = fullfile(piRootPath,'data','V4','teapot-set','TeaTime.fbx');
% convert fbx to pbrt
pbrtFile = piFBX2Recipe(fbxFile);
% format this file 
formattedFname = piPBRTReformat(pbrtFile);
thisR = piRead(formattedFname);
%%
% close up view
thisR.set('from',[196.45 24.64 3.37]);
thisR.set('to',  [96.55 20.50 1.98]);
thisR.set('up',  [0 1 0]);

thisR.set('film resolution',[500 500]);
thisR.set('rays per pixel',64)
%% set render type
% radiance 
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})

%% write the data out
piWrite(thisR);

%% render the scene
scene = piRender(thisR);
sceneWindow(scene);
