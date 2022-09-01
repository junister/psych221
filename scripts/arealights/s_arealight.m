%% Explore light creation with the area light parameters
%
%
% See also
%   t_arealight.m, t_piIntro_light

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a proper default for piLightCreate
fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);

thisR.set('light','AreaLightRectangle_L','delete');
thisR.set('light','AreaLightRectangle.001_L','delete');
thisR.set('light','AreaLightRectangle.002_L','delete');
thisR.set('light','AreaLightRectangle.003_L','delete');

thisR.set('lights','all','delete');

%%  Put in a white light of our own.

wLight    = piLightCreate('white','type','area');
thisR.set('light',wLight,'add');
thisR.set('asset',wLight.name,'world rotation',[-90 0 0]);
piWRS(thisR,'render flag','hdr');

%% Load the Macbeth scene. It has no default light.

thisR =  piRecipeDefault('scene name','MacBethChecker');

wLight    = piLightCreate('white','type','area');
thisR.set('light',wLight,'add');
thisR.set('light',wLight.name,'world rotation',[-90 0 0]);
thisR.set('light',wLight.name,'translate',[0 4 0]);

piWRS(thisR,'render flag','rgb');

%%  When you reduce the spread, the total amount of light stays the same

% So local regions actually get brighter.  But the fall off at the
% edges is higher.
thisR.set('light',wLight.name,'spread',15);
piWRS(thisR,'render flag','rgb');

% piLightCreate('list available types')

%% Add a top down area light

thisR =  piRecipeDefault('scene name','ChessSet');

thisR.set('lights','all','delete');

wLight    = piLightCreate('light1','type','area');
thisR.set('light',wLight,'add');
thisR.set('light',wLight.name,'world rotation',[-90 0 0]);
thisR.set('light',wLight.name,'translate',[1 2 0]);
thisR.set('light',wLight.name,'spread',30);
thisR.set('light',wLight.name,'spd',[32 32 255]);
% thisR.get('light',wLight.name,'world position')

wLight    = piLightCreate('light2','type','area');
lName = wLight.name;
thisR.set('light',wLight,'add');
thisR.set('light',lName,'world rotation',[-90 0 0]);
thisR.set('light',lName,'translate',[-1 2 0]);
thisR.set('light',lName,'spread',10);
thisR.set('light',lName,'spd',[255 255 0]);

% thisR.show('lights');

scene = piWRS(thisR,'render flag','rgb');
ieReplaceObject(piAIdenoise(scene));
sceneWindow;

%% Contrast with the effect of adding a spot light

thisR =  piRecipeDefault('scene name','ChessSet');
thisR.set('lights','all','delete');

lightName = 'new_spot_light_L';
newLight = piLightCreate(lightName,...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 1, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);
thisR.set('light', newLight, 'add');

% When we position a light, it is treated as an asset.
% Perhaps we should duplicate the world position and other sets in the
% 'light' subcategory.  Or at least catch it in the 'light' case and
% send it to the 'asset' case.  Something more thoughtful.
thisR.set('asset',lightName,'world position',[3.4544  0  0.15036]);
piAssetGeometry(thisR);

piWRS(thisR,'gamma',0.7);

%% END

