% t_radianceIrradiance - Method for determining Irradiance from
%                        measured radiance off the surface
%
% See also
%   t_materials.m, tls_materials.mlx, t_assets, t_piIntro*,
%   piMaterialCreate.m
%


%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create recipe

thisR = piRecipeCreate('sphere');
thisR.show('lights');

thisR.set('lights','all','delete');
% spot light doesn't seem to be working
thisLight = piLightCreate('area light', 'type','area','rgb spd',[1 1 1]);
thisLight.cameracoordinate = true; % not set by default

thisR.set('lights',thisLight,'add');
thisR.show('lights');

% thisR.set('skymap','room.exr');

% A low resolution rendering for speed
thisR.set('film resolution',[200 150]);
thisR.set('rays per pixel',256);
thisR.set('nbounces',10); 
thisR.set('fov',45);
piWRS(thisR,'name','diffuse');

% To insert one of those materials into the recipe, 
mirrorName = 'mirror';
piMaterialsInsert(thisR,'name',mirrorName);

% Assigning mirror to sphere
assetSphere = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset', assetSphere, 'material name', mirrorName);

%%
% add a skymap as a test
fileName = 'room.exr';
%thisR.set('skymap',fileName);

piWrite(thisR);
%piWRS(thisR,'name','mirror','render flag','hdr');
scene = piRender(thisR);
sceneWindow(scene);


