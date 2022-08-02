%% s_chromaticAberration.m
%
% Demonstrate the chromatic aberration present in lens rendering. Adapted
% from a sample scene
%
% TL SCIEN Team, 2018
% v4 version initial work D.Cardinal 2022

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt scene
% Read the main scene pbrt file.  Return it as a recipe
% (used to use textured plane, but it's not in v4)
useScene = 'cornell_box';
thisR = piRecipeDefault('scene name', useScene);
% add a light so we can see
pointLight = piLightCreate('point','type','point','cameracoordinate', true);
thisR.set('light',pointLight, 'add');

%% Attach a desired texture to part of the scene
ourAsset = '001_large_box_O';
piMaterialsInsert(thisR,'names','slantededge');
piAssetTranslate(thisR,ourAsset,[.15 .11 0]);
thisR.set('asset',ourAsset,'material name','slantededge');

%% Attach a camera with a lens
thisR.set('camera',piCameraCreate('omni'));     % Has a lens
thisR.set('aperture',7);             % mm
thisR.set('film resolution',512);    % Spatial samples
thisR.set('rays per pixel',128);     % Rendering samples
thisR.set('film diagonal', 2);            % Size of film in mm
thisR.set('focusdistance',1.6); % to the large box

fprintf('Rendering with lens:   %s\n',thisR.get('lens file'));


%% Turn on chromatic aberration and render

% This takes longer because we are using more wavelength samples to
% trace through the lens (8 bands by default).
thisR.set('chromatic aberration',true);
piWRS(thisR,'name','8 CA bands');

%% Render without chromatic aberration
thisR.set('chromatic aberration',false);

% the old version did a file copy here, but
% I'm not sure we need it?
piWrite(thisR);

[oi, results] = piRender(thisR,'render type','radiance');
oi = oiSet(oi,'name','noCA');

% Show it in ISET
oiWindow(oi);  

%% Now with 15 bands
thisR.set('chromatic aberration',15);
piWrite(thisR);

[oiCA, results] = piRender(thisR,'render type','radiance');
oiCA = oiSet(oiCA,'name','CA 15 bands');
oiWindow(oiCA);

%% End