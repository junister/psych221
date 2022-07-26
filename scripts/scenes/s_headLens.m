%% s_headLens
%


%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','head');

thisR.set('rays per pixel',512);
thisR.set('film resolution',[320 320]*2);
thisR.set('n bounces',5);
%% This renders
[scene, results] = piWRS(thisR);

thisR.set('asset','001_head_O','rotate',[5 20 0]);
[scene, results] = piWRS(thisR);

%% Change the camera position
oFrom = thisR.get('from');
oTo = thisR.get('to');

thisR.set('object distance', 1.3);

thisR.set('lights','all','delete');
thisR.set('skymap','room.exr');
% thisR.set('from',oFrom);
[scene, results] = piWRS(thisR);

%% We would like to rotate around the 'up' direction!!!

%% Textures on the head.
%
% The white is good for the illumination!

thisR.set('from',oFrom);
thisR.set('object distance', 1.5);
thisR.set('from',oFrom + [0 0 0.1]);
[scene, results] = piWRS(thisR);

%%  Materials
thisR.set('lights','all','delete');
thisR.set('skymap','brightfences.exr');

[scene, results] = piWRS(thisR);
thisR.get('print materials')
piMaterialsInsert(thisR);
thisR.show('objects')

thisR.set('asset','head','material name','White');
thisR.set('asset','001_head_O','material name','White');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','marbleBeige');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','mahogany_dark');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','mirror');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','macbethchart');
piWRS(thisR);
thisR.get('texture','macbethchart')
ans.scale
thisR.set('texture','macbethchart','scale',0.3);
piWRS(thisR);
thisR.set('texture','macbethchart','uscale',0.3);
thisR.set('texture','macbethchart','vscale',0.3);
piWRS(thisR);
thisR.set('texture','macbethchart','vscale',10);
thisR.set('texture','macbethchart','uscale',10);

thisR.set('asset','001_head_O','material name','head');

piWRS(thisR);


%%
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
