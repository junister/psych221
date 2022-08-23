%% s_kitchen
%
% Worked with cardinal download on July 11, 2022
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Se6t up the parameters

resolution = [320 320]*1;

thisR = piRecipeDefault('scene name','kitchen');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

%% This renders the scene

scene = piWRS(thisR);
dRange = sceneGet(scene,'depth range');

%{
piMaterialsInsert(thisR,'name','marble-beige');
idx = piAssetSearch(thisR,'material name','Worktops');
for ii=1:numel(idx)
 thisR.set('asset',idx(ii),'material name','marble-beige');
end
scene = piWRS(thisR);

%}

%{

% Swapping out ALL the materials.  
% Next, we should find the objects with just some
% material.
oNames = thisR.get('object names');

%%
piMaterialsInsert(thisR,'name','diffuse-white');
for ii=1:numel(oNames)
  thisR.set('asset',oName{ii},'material name','diffuse-white');
end
scene = piWRS(thisR);

%%
piMaterialsInsert(thisR,'name','wood-light-large-grain');
oNames = thisR.get('object names');
for ii=1:numel(oNames)
  thisR.set('asset',oName{ii},'material name','wood-light-large-grain');
end
scene = piWRS(thisR);

%%
piMaterialsInsert(thisR,'name','glass-bk7');
thisR.set('n bounces',10);

oNames = thisR.get('object names');
for ii=1:numel(oNames)
  thisR.set('asset',oName{ii},'material name','glass-bk7');
end
scene = piWRS(thisR,'render flag','rgb');

%%
piMaterialsInsert(thisR,'name','metal-ag');
thisR.set('n bounces',5);

oNames = thisR.get('object names');
for ii=1:numel(oNames)
  thisR.set('asset',oName{ii},'material name','metal-ag');
end
scene = piWRS(thisR,'render flag','rgb');

%}
%% Samples the scene from a few new directions around the current from

from = thisR.get('from'); to = thisR.get('to');
direction = thisR.get('fromto');
direction = direction/norm(direction);
nsamples = 5;
frompts = piRotateFrom(thisR,direction,'nsamples',nsamples,'degrees',5,'method','circle');

%% Do it.
for ii=1:size(frompts,2)
    fprintf('Point %d ... of %d\n',ii,size(frompts,2));
    thisR.set('from',frompts(:,ii));
    piWRS(thisR,'render flag','hdr');
    fprintf('\n');
end

%%
thisR.set('from',from); thisR.set('to',to);
piWRS(thisR);

%%  You can see the depth from the depth map.
% scenePlot(scene,'depth map');

%% Another double Gauss

% lensList
lensfile  = 'dgauss.22deg.3.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film diagonal',5);    % 3 mm is small
thisR.set('object distance',2);  % Move closer. The distance scaling is weird.
[~,results] = piWRS(thisR,'name','DG');

%% Fisheye

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.set('film diagonal',7);  %% 3 mm is small

thisR.camera = piCameraCreate('omni','lensFile',lensfile);
oi = piWRS(thisR,'name','fisheye');
oi = piAIdenoise(oi);
oiWindow(oi);

%% END

