%% t_lightHeadlamp
%
%   Use Projected Light Headlamps
%   Also try to evaluate radiance over the FOV
%
%   D. Cardinal, Stanford University, September, 2023
%
% See also
%  (based on) t_lightProjection
%  t_lightGonimetric
%  t_piIntro_lights

%% Initialize ISET and Docker
% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name','flatSurface');

thisR.set('name','Headlamp');  % Name of the recipe

thisR.show('lights');

% for flat surface
thisR.lookAt.from = [3 290 0];
thisR.lookAt.to = [3 50 0];

%% show original
piWRS(thisR,'mean luminance',-1);

%% Change the flat surface to a mirror

mirrorName = 'mirror';
piMaterialsInsert(thisR,'name',mirrorName);

% Assigning mirror to sphere
cube = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset', cube, 'material name', mirrorName);

%% show with a mirror
piWRS(thisR,'mean luminance',-1);

%% Add Headlamp

% scale appears to be how much to scale the image intensity. We haven't
% seen a difference yet between scale and power fov seems to be working
% well, changing how widely the projection spread.
%

headlight = headlamp('preset','level beam','name', 'headlightLight');
headlightLight = headlight.getLight;

% On the surface scale & power do "the same thing" but they
% definitely don't in the pbrt code.

% Example outputs:
% scale power meanluminance 
%  10,   20,   254
%  10,   10,   127
%  20,   10,   254
%  20,   -1,     5.9
%  10,   -1,     3
%  10,    1,    12.7
%  10,    0,     3

% Remove all the lights
thisR.set('light', 'all', 'delete');

% Add the Headlamp(s)
thisR.set('light', headlightLight, 'add');

pLight_Left = piAssetSearch(thisR,'light name', 'headlightLight');
%pLight_Right = piAssetSearch(thisR,'light name', 'Right_Light');
%thisR.set('asset',pLight_Left,'translation',[0 0 150]);

thisR.show('lights');

%%
piWRS(thisR,'mean luminance',-1);


%%
piWRS(thisR,'mean luminance',-1);

%% Rotate the light

%thisR.set('asset',pLight_Left,'rotation',[0 0 30]);
%piWRS(thisR,'mean luminance',-1);

% thisR.set('render type',{'radiance','depth'});
% scene = piRender(thisR);
% sceneWindow(scene);

%%
%thisR.set('asset',pLight_Right,'translate',[1 1 0]);
%thisR.show('lights');

%piWRS(thisR);
