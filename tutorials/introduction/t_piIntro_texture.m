% t_piIntro_texture
%
% Textures are part of the material definition.  We have routines that
% create materials with pre-assigned textures, and some of the parameters
% of these textures can be modified. 
% 
% This script illustrates how we use piMaterialsInsert to include materials
% with pre-assigned textures into a recipe. We render the materials on a
% flat surface in the first few examples.  Then we assign the textures to
% individual assets in the SimpleScene.
%
% See also
%  t_piIntro_light, tls_assets.mlx

%% Init
ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name', 'flatSurfaceWhiteTexture');

%% Add a light and render

thisR.set('lights','all','delete');
newDistLight = piLightCreate('Distant 1',...
    'type', 'distant',...
    'cameracoordinate', true,...
    'spd', 'equalEnergy');
thisR.set('light',  newDistLight, 'add');
thisR.get('light print');

%%
piWRS(thisR,'name','random color');

%% This is description of the scene

% We list the textures, lights and materials.
thisR.get('texture print');
thisR.get('lights print');
thisR.get('material print');

%% Change the texture of the checkerboard.

% There are several built-in texture types that PBRT provides.  These
% include
%
%  checkerboard, dots, imagemap
%
% You set the parameters of the checks and dots.  You specify a PNG or an
% EXR file for the image map.
%

% Textures are attached to a material.  The checks, dots and others are
% created and inserted this way - see the code there if you want to do it
% yourself.
thisR = piMaterialsInsert(thisR,'names','checkerboard');

% Set the material to the object
thisR.set('asset','001_Cube_O','material name','checkerboard');

% Write and render the recipe with the new texture
piWRS(thisR,'name','checks');

% There are many properties of the checks you can change
%{
%}

%%  That felt good.  Let's make colored dots.

% Set the material to the object
thisR = piMaterialsInsert(thisR,'names','dots');
thisR.set('asset','001_Cube_O','material name','dots');

thisR.get('texture','dots','uscale')

% Write and render the recipe with the new texture
piWRS(thisR,'name','dots-orig');

%% These scale factor change the dot densities
% Other parameters change other visual properties.
thisR.set('texture','dots','vscale',16);
thisR.set('texture','dots','uscale',16);

% Write and render the recipe with the new texture
piWRS(thisR,'name','dots16');

%% Now we change the texture of a material in a more complex scene

thisR = piRecipeDefault('scene name', 'SimpleScene');
piMaterialsInsert(thisR,'groups','testpatterns');

oNames = thisR.get('object names no id');
idx = piContains(oNames,'Plane');
thePlane = oNames(idx);

thisR.set('asset',thePlane{1},'material name','dots');

piWRS(thisR);

%%  We have many more complex textures, including those based on images.

% Pull in a couple of wood types
piMaterialsInsert(thisR,'groups','wood');
thisR.get('print materials');
thisR.set('asset',thePlane{1},'material name','wood-medium-knots');

piWRS(thisR);

%% Let's change the texture of a the sphere to checkerboard

idx = piContains(oNames,'Sphere');
theSphere = oNames(idx);
thisR.set('asset',theSphere{1},'material name','checkerboard');

% We should figure out what all these parameters do
%{
thisR.get('texture','checkerboard')
%}

thisR.set('texture','checkerboard','uscale',1);
thisR.set('texture','checkerboard','vscale',0.5);

piWRS(thisR);

%% END