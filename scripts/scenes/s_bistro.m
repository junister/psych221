%% s_bistro
%
% Worked with cardinal download on July 11, 2022
%
%

thisR = piRecipeDefault('scene name','bistro');
thisR.set('rays per pixel',256);
thisR.set('film resolution',[320 320]);
thisR.set('render type',{'radiance','depth'});

thisR = piRecipeDefault('scene name','bistro_vespa');
thisR.set('rays per pixel',256);
thisR.set('film resolution',[320 320]);
thisR.set('render type',{'radiance','depth'});

thisR = piRecipeDefault('scene name','bistro_boulangerie');
thisR.set('rays per pixel',256);
thisR.set('film resolution',[320 320]);
thisR.set('render type',{'radiance','depth'});

%% This renders
scene = piWRS(thisR);

%%

% depthRange = thisR.get('depth range');
% depthRange = [1 1];

% thisR.set('lens file','fisheye.87deg.100.0mm.json');
% lensFiles = lensList;
lensfile  = 'dgauss.22deg.50.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',[320 320]*2);
thisR.set('focal distance',10);
thisR.set('film diagonal',100);  %% 33 mm is small
thisR.set('object distance',5);  % Move closer. 
piWRS(thisR,'name','DG fov 5m');

%% Another double Gauss

% lensfile  = 'dgauss.22deg.50.0mm.json';    % 30 38 18 10
lensfile = 'dgauss.77deg.3.5201mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',[320 320]*2);
thisR.set('film diagonal',3);  %% 33 mm is small
thisR.set('object distance',10);  % Move closer. 
piWRS(thisR,'name','DG fov 10m');

%% Fisheye

lensfile = 'fisheye.87deg.100.0mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',[320 320]*2);
thisR.set('film diagonal',200);  %% 33 mm is small
thisR.set('object distance',5);  % Move closer. 
oi = piWRS(thisR,'name','fisheye 5m');


