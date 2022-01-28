%% s_chromaticAberrationv3.m
%
% Demonstrate the chromatic aberration present in lens rendering. Adapted
% from s_texturedPlane.m
%
% TL SCIEN Team, 2018

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt scene
% Read the main scene pbrt file.  Return it as a recipe
useScene = 'cornell_box';
thisR = piRecipeDefault('scene name', useScene);
% add a light
pointLight = piLightCreate('point','type','point','cameracoordinate', true);
thisR.set('light',pointLight, 'add');

%% Scale and translate the plane
scale = 0.5; % 1*0.5 = 0.5 m
translate = 1; % m

% The (textured) plane has specifically been named "Plane" in this scene. We
% also know that our camera is located at the origin and looking down the
% positive y-axis. 
% Note: The order of scaling and translating matters!
%piAssetScale(thisR,'Checkerboard_B',[scale scale scale]); % The plane is oriented in the x-z plane
%piAssetTranslate(thisR,'Checkerboard_B',[0 0 translate]); 

%% Attach a desired texture
%imageName = 'squareResolutionChart.exr';
%imageFile = fullfile(piRootPath,'data','imageTextures',imageName);

%copyfile(imageFile,workingDir);
%thisR = piWorldFindAndReplace(thisR,'dummyTexture.exr',imageName);

%% Attach a lens

thisR.set('camera',piCameraCreate('omni'));     % Has a lens
thisR.set('aperture',2);             % mm
thisR.set('film resolution',128);    % Spatial samples
thisR.set('rays per pixel',128);     % Rendering samples
thisR.set('film diagonal', 10);            % Size of film in mm
thisR.set('focusdistance',1)

fprintf('Rendering with lens:   %s\n',thisR.get('lens file'));


%% Turn on chromatic aberration and render

% This takes longer because we are using more wavelength samples to
% trace through the lens (8 bands).
thisR.set('chromatic aberration',true);
piWrite(thisR);

[oiCA, results] = piRender(thisR,'render type','radiance');
oiCA = oiSet(oiCA,'name','CA');
oiWindow(oiCA);

%% Render without chromatic aberration

thisR.set('chromatic aberration',false);

% the old version did a file copy here, but
% I'm not sure we need it?
piWrite(thisR);

[oi, results] = piRender(thisR,'render type','radiance');
oi = oiSet(oi,'name','noCA');

% Show it in ISET
oiWindow(oi);  

%% Now with only 4 bands
thisR.set('chromatic aberration',15);
piWrite(thisR);

[oiCA, results] = piRender(thisR,'render type','radiance');
oiCA = oiSet(oiCA,'name','CA');
oiWindow(oiCA);

%% End