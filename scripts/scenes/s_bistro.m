%% s_bistro
%
% Worked with cardinal download on July 11, 2022
%
%

resolution = [640 640]*2;

thisR = piRecipeDefault('scene name','bistro');
thisR.set('rays per pixel',256);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

%%  
thisR = piRecipeDefault('scene name','bistro_vespa');
thisR.set('rays per pixel',256);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

%%
thisR = piRecipeDefault('scene name','bistro_boulangerie');
thisR.set('rays per pixel',256);
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

thisR.set('film resolution',resolution);
thisR.set('film diagonal',5);  %% 33 mm is small
thisR.set('object distance',10);  % Move closer. 
piWRS(thisR,'name','DG 10m');

%% Fisheye

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',resolution);
thisR.set('film diagonal',5);  %% 33 mm is small
thisR.set('object distance',10);  % Move closer. 
oi = piWRS(thisR,'name','fisheye 10m');

%%

