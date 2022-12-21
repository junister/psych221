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

% dRange = sceneGet(scene,'depth range');

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

