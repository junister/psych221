%% pbrt v4 introduction 
%
% The proper versions of Docker image(s) need to be on the machine
% where they will execute.  Typically GPU images are already
% installed on the remote machine.
%
% If Docker doesn't pull the CPU image needed for local operations,
% you can do it manually:
%
%     docker pull camerasimulation/pbrt-v4-cpu
%
% To have rendering occur on a remote GPU see the Wiki page:
%   https://github.com/ISET/iset3d-v4/wiki/Remote-Rendering-with-PBRT-v4
% 
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
% convert scene unit from centimeter to meter
% thisR = piUnitConvert(thisR, 100);

thisR.set('film resolution',[600 600]/2);
thisR.set('rays per pixel',32);
%% set render type
% radiance 
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'});
%% move object
thisR.set('asset','Cylinder.001_B','world translation',[0.2 0 0]);

thisR.show('objects');
%%
piLightDelete(thisR, 'all'); 
lightName = 'new light';
newLight = piLightCreate(lightName,...
                        'type','infinite',...
                        'spd',[0.4 0.3 0.3],...
                        'specscale',1);
thisR.set('light', newLight, 'add');

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

