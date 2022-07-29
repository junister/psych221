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

%% Samples the scene from a few new directions around the current from

direction = thisR.get('fromto');
pts = piRotateFrom(thisR,direction,'nsamples',4,'radius',0.5);

from = thisR.get('from');
to   = thisR.get('to');

for ii=1:size(pts,2)
    thisR.set('from',pts(:,ii));
    thisR.get('to')
    piWRS(thisR);
end

thisR.set('from',from); thisR.set('to',to);
piWRS(thisR);

%%  You can see the depth from the depth map.
% scenePlot(scene,'depth map');

%% Another double Gauss

% lensList
lensfile  = 'dgauss.22deg.3.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film diagonal',5);  %% 33 mm is small
thisR.set('object distance',2);  % Move closer. The distance scaling is weird.
[oi,results] = piWRS(thisR,'name','DG');

%% Fisheye

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
oi = piWRS(thisR,'name','fisheye');
oi = piAIdenoise(oi);
oiWindow(oi);

%%

