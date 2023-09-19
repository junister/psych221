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

thisR = piRecipeCreate('Sphere');
%thisR = piRecipeCreate('flatsurface');
thisR.show('lights');

thisR.set('lights','all','delete');

thisLight = piLightCreate('spot light', 'type','spot','rgb spd',[100 100 100]);
thisLight.cameracoordinate = true; % not set by default

thisR.set('lights',thisLight,'add');
thisR.show('lights');

%thisR.set('skymap','room.exr');

thisR.set('film resolution',[400 300]);
thisR.set('rays per pixel',512);
thisR.set('nbounces',3); 
thisR.set('fov',45);

% try moving the subject really close
assetSphere = piAssetSearch(thisR,'object name','Sphere');
piAssetTranslate(thisR,assetSphere,[0 0 -298]);

piWRS(thisR,'name','diffuse','mean luminance', -1); % works


piMaterialsInsert(thisR,'name','mirror'); % fail
piMaterialsInsert(thisR,'name','glass'); % fail
piMaterialsInsert(thisR,'name','glass-f5'); % fail
piMaterialsInsert(thisR,'name','metal-ag'); % fail
piMaterialsInsert(thisR,'name','rough-metal'); % fail
piMaterialsInsert(thisR,'name','chrome'); % fail
piMaterialsInsert(thisR,'name','glossy-red'); % works

% To use one of those materials into the recipe: 
useMaterial = 'glass-f5';

% Assigning new surface to sphere
thisR.set('asset', assetSphere, 'material name', useMaterial);

%%
% add a skymap as a test
fileName = 'room.exr';
%thisR.set('skymap',fileName); % works

piWrite(thisR);
%piWRS(thisR,'name','mirror','render flag','hdr');
scene = piRender(thisR, 'mean luminance',-1);
sceneWindow(scene);


