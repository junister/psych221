%% pbrt v4 introduction 
%
% The proper versions of these containers need to be on the machine
% where they will execute.  Typically the GPU containers are already
% installed on the remote machine.
%
% Users typically pull their own copy of the CPU docker image(s):
%
%     docker pull camerasimulation/pbrt-v4-cpu
%
% EXPERIMENTAL FOR GPU SUPPORT!
%
% and/or     docker pull digitalprodev/pbrt-v4-gpu-ampere-bg
% and/or     docker pull camcerasimulation/pbrt-v4-t4  
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
if ~piDockerExists, piDockerConfig; end

%% piRead support FBX and PBRT
% FBX is converted into PBRT
fbxFile = fullfile(piRootPath,'data','V4','teapot-set','TeaTime.fbx');
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
thisR.set('film render type',{'radiance'});
%% move object
thisR.set('asset','Cylinder.001_B','world translation',[0.2 0 0]);

thisR.show('objects');
%%
piLightDelete(thisR, 'all'); 
lightName = 'new light';
newLight = piLightCreate(lightName,...
                        'type','point',...
                        'blackbody spd',[0.4 0.3 0.3],...
                        'specscale',1);
thisR.set('light', 'add', newLight);

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

