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

thisLight = piLightCreate('spot',...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 100, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);

thisR.set('lights',thisLight,'add');
thisR.show('lights');

%thisR.set('skymap','room.exr');

thisR.set('film resolution',[300 200]);
thisR.set('rays per pixel',128);
thisR.set('nbounces',3); 
thisR.set('fov',45);

% try moving the subject really close
assetSphere = piAssetSearch(thisR,'object name','Sphere');
piAssetTranslate(thisR,assetSphere,[0 0 -200]);

piWRS(thisR,'name','diffuse','mean luminance', -1); % works


piMaterialsInsert(thisR,'name','mirror'); % fail
piMaterialsInsert(thisR,'name','glass'); % fail
piMaterialsInsert(thisR,'name','glass-f5'); % fail
piMaterialsInsert(thisR,'name','metal-ag'); % fail
piMaterialsInsert(thisR,'name','rough-metal'); % fail
piMaterialsInsert(thisR,'name','chrome'); % fail
piMaterialsInsert(thisR,'name','glossy-red'); % works

% To use one of those materials into the recipe: 
useMaterial = 'chrome';

% Assigning new surface to sphere
thisR.set('asset', assetSphere, 'material name', useMaterial);

%%
% add a skymap as a test
fileName = 'room.exr';
%thisR.set('skymap',fileName); % works

piWRS(thisR,'name', 'reflective', 'mean luminance',-1);

%% Try aiming a light straight at us
% spot & point & area don't seem to work
reverseLight = piLightCreate('reverse',...
                        'type','point',...
                        'spd','equalEnergy',...
                        'specscale', 100, ...
                        'cameracoordinate', true);
%{
                        'coneangle', 60,...
                        'conedeltaangle', 10, ...
%}

thisR.set('lights',reverseLight,'add');

rLight = piAssetSearch(thisR,'light name','reverse');
thisR.set('asset',rLight,'translate',[0 0 30]);
thisR.set('asset',rLight,'rotate',[0 180 0]);

% With sphere
piWRS(thisR,'name','reverse light', 'mean luminance', -1);

% Try without the sphere
thisR.set('asset', assetSphere, 'delete');
piWRS(thisR,'name','no sphere', 'mean luminance', -1);
