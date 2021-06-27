%% pbrt v4 introduction 
% CPU only
%%
ieInit;
%% support FBX to PBRT

fbxFile   = fullfile(piRootPath,'data','V4','teapot-set','TeaTime.fbx');
% convert fbx to pbrt
pbrtFile = piFBX2PBRT(fbxFile);
% format this file 
infile = piPBRTReformat(pbrtFile);

%%
thisR  = piRead(infile);
%%
% close up view
thisR.set('from',[196.45 24.64 3.37]);
thisR.set('to',  [96.55 20.50 1.98]);
thisR.set('up',  [0 1 0]);

thisR.set('film resolution',[300 300]*4);
thisR.set('rays per pixel',256)
%% set render type
% radiance 
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})

%% write the data out
piWrite(thisR);

%% render the scene
% [scene,result] = piRender(thisR);
tic
scene = piRenderCloud(thisR);
sceneWindow(scene);
toc
%%
piAssetGeometry(thisR);
