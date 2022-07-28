%% s_kitchen
%
% Worked with cardinal download on July 11, 2022
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Se6t up the parameters

resolution = [640 640]*0.5;

thisR = piRecipeDefault('scene name','kitchen');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

%% This renders the scene

scene = piWRS(thisR);

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

