%% s_headLens

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','head');

thisR.set('rays per pixel',512);
thisR.set('film resolution',[320 320]*2);

%% This renders
scene = piWRS(thisR);

% The depth map is crazy, though.
% scenePlot(scene,'depth map');

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
