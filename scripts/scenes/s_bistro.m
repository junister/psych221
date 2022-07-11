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
% lensfile = 'fisheye.87deg.100.0mm.json';
% lensfile  = 'dgauss.22deg.50.0mm.json';    % 30 38 18 10

fprintf('Using lens: %s\n',lensfile);
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('focal distance',5);
thisR.set('film diagonal',33);

oi = piWRS(thisR);
