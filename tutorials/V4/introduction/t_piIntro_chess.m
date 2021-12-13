%% pbrt v4 introduction 
% Users need to pull the docker image(s):
%     Current temporary locations
%     docker pull camerasimulation/pbrt-v4-cpu
%     docker pull digitalprodev/pbrt-v4-cpu
%
% EXPERIMENTAL FOR GPU SUPPORT!
% and/or     docker pull digitalprodev/pbrt-v4-gpu-ampere-bg
% and/or     docker pull digitalprodev/pbrt-v4-gpu-ampere-mux
% and/or     docker pull camerasimulation/pbrt-v4-t4  
% 
% CPU only
% blender uses a coordinate system like this:
%    
%                 z
%                 ^  
%                 |
%                 |  
%                 x - - - - >y
% unit scale uses centermeter by default
%
% We modified
%    tree
%   added piWRS.m
%
% TO CHECK for updates
%    recipe.m, recipeSet.m recipeGet.m
%    
%   
%% Init
ieInit;


%% piRead support FBX and PBRT
% FBX is converted into PBRT
%fbxFile = fullfile(piRootPath,'data','V4','teapot-set','TeaTime.fbx');
% or you can use a PBRT file
fbxFile = fullfile(piRootPath,'data','V4','ChessSet','ChessSet.pbrt');
%% 
thisR  = piRead(fbxFile);
%%
% close up view
thisR.set('from',[1.9645 0.2464 0.0337]);
thisR.set('to',  [0.9655 0.2050 0.0198]);
thisR.set('up',  [0 1 0]);

thisR.set('film resolution',[600 600]/2);
thisR.set('rays per pixel',32);
%% set render type
% radiance 
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})

thisR.show('objects');
%%
piLightDelete(thisR, 'all'); 
mainLight = piLightCreate('mainLight', ...
                        'type','distant',...
                        'specscale', 3,...
                        'cameracoordinate', true);
thisR.set('light', 'add', mainLight);
                    
lightName = 'env light';
envLight = piLightCreate(lightName,...
                        'type','infinite',...
                        'spd',[0.4 0.3 0.3],...
                        'specscale',1, ...
                        'mapname', 'sun-clouds.exr');

thisR.set('light', 'add', envLight);

%% write the data out

scene = piWRS(thisR);
 %{
tic
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);
toc
%}
%%
piAssetGeometry(thisR);

