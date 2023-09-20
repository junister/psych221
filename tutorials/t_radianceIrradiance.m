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

%thisR.show('lights');
thisR.set('lights','all','delete');

% For baseline use a spot light so we can see where things are
thisLight = piLightCreate('spot',...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 100, ...
                        'coneangle', 30,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);

thisR.set('lights',thisLight,'add');
%thisR.show('lights');

% Optionally add a skymap so everything is nicely lit
% thisR.set('skymap','room.exr');
% thisR.set('lights','room_L','specscale',1e-3);

thisR.set('film resolution',[300 200]);
thisR.set('rays per pixel',512);
thisR.set('nbounces',3); 
thisR.set('fov',45);

% Move our sphere off to the side & scale it to allow for a second one
assetSphere = piAssetSearch(thisR,'object name','Sphere');
% piAssetTranslate(thisR,assetSphere,[100 0 00]);
% piAssetScale(thisR,assetSphere,[.5 .5 .5]);

% Baseline -- single diffuse sphere
piWRS(thisR,'name','diffuse','mean luminance', -1); % works

%% Now try to get a reflective material working
piMaterialsInsert(thisR,'name','mirror'); % fail
piMaterialsInsert(thisR,'name','glass'); % fail
piMaterialsInsert(thisR,'name','glass-f5'); % fail
piMaterialsInsert(thisR,'name','metal-ag'); % fail
piMaterialsInsert(thisR,'name','rough-metal'); % fail
piMaterialsInsert(thisR,'name','chrome'); % fail
piMaterialsInsert(thisR,'name','glossy-red'); % works

% To use one of those materials into the recipe: 
useMaterial = 'mirror';
useMaterial = 'glossy-red';
useMaterial = 'rough-metal';

% Assigning new surface to sphere
thisR.set('asset', assetSphere, 'material name', useMaterial);
piWRS(thisR,'name',useMaterial,'mean luminance', -1); % works

%% Optionally add a skymap as a test
% since it seems to light everything
fileName = 'room.exr';
%thisR.set('skymap',fileName); % works

%{ 
% here is a light that sort of works, hand-coded for now
AttributeBegin
  AreaLightSource "diffuse" "blackbody L" [ 6500 ] "float power" [ 100 ]
  Translate 0 10 0
  Shape "sphere" "float radius" [ 20 ]
AttributeEnd
%}

% create a test area light (create doesn't like shape?)
lightTest = piLightCreate('lightTest','type','area', ...
    'radius',20, 'specscale',1, 'rgb spd',[1 1 1], ...
    'cameracoordinate',true);

% This doesn't work as coded, not sure how to set shape to sphere
%so now try to set the shape -- But this doesn't work
%lightTest = piLightSet(lightTest,'shape','sphere');

thisR.set('light',lightTest,'add');
piWRS(thisR,'name', useMaterial, 'mean luminance',-1);

%% Now add a headlamp
% Currently this illuminates diffuse surfaces, but doesn't seem to have
% any measurable impact on reflective or dielectric objects
% NB Requires ISETAuto for headlamp
forwardHeadLight = headlamp('preset','level beam', 'name','forward'); 
forwardLight = forwardHeadLight.getLight(); % get actual light

thisR.set('lights',forwardLight,'add');

% Move the headlamp closer to the spheres
fLight = piAssetSearch(thisR,'light name','forward');
thisR.set('asset',fLight,'translate',[0 0 300]);
piWRS(thisR,'name', 'headlamp', 'mean luminance',-1);

%% Try adding a second sphere
% Off to the right of the first one, also scaled down
sphere2 = piAssetLoad('sphere');
assetSphere2 = piAssetSearch(sphere2.thisR,'object name','Sphere');
piAssetTranslate(sphere2.thisR,assetSphere2,[-100 0 00]);
piAssetScale(sphere2.thisR,assetSphere2,[.5 .5 .5]);

thisR = piRecipeMerge(thisR,sphere2.thisR, 'node name',sphere2.mergeNode,'object instance', false);
piWRS(thisR,'name','second sphere', 'mean luminance', -1);

%% Try aiming a light straight at us
% spot & point & area & headlamp don't seem to work
reverseHeadLight = headlamp('preset','level beam', 'name','reverse'); 
reverseLight = reverseHeadLight.getLight(); % get actual light
thisR.set('lights',reverseLight,'add');

% Move it out from the camera and rotate it to look back
rLight = piAssetSearch(thisR,'light name','reverse');
thisR.set('asset',rLight,'translate',[0 0 160]);

% Note: We can see te effect of the headlamp on the spheres if we leave it
% pointed in the direction of the camera. But if we rotate it 180, we don't
% see any evidence of it. ...
thisR.set('asset',rLight,'rotate',[0 180 0]);

% With reverse light
piWRS(thisR,'name','reverse light', 'mean luminance', -1);

% Make both spheres reflective
sphereIndices = piAssetSearch(thisR,'object name','sphere');
for ii = 1:numel(sphereIndices)
    thisR.set('asset', sphereIndices(ii), 'material name', useMaterial);
end
piWRS(thisR,'name','two reflective spheres', 'mean luminance', -1);

% Try without the sphere
thisR.set('asset', assetSphere, 'delete');
piWRS(thisR,'name','no primary sphere', 'mean luminance', -1);
