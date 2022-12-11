% Demonstrate adding character text to a usable scene

% D. Cardinal, Stanford University, December, 2022

%%

% Use a background scene
% Download Kitchen Scene if needed
% ieWebGet('resourcename','kitchen','resourcetype','pbrtv4')

% Get the full path to the Kitchen scene
kitchenSceneFile = which('kitchen.pbrt');

% Load our scene
kitchenR = piRead(kitchenSceneFile);

% Add some lights and specify some defaults
% Add an equal energy distant light for uniform lighting
spectrumScale = 20;
lightSpectrum = 'equalEnergy';
baseLight = piLightCreate('Distant  Light',...
    'type', 'distant',...
    'specscale float', spectrumScale,...
    'spd spectrum', lightSpectrum,...
    'cameracoordinate', true);
kitchenR.set('light', baseLight, 'add');

kitchenR.set('integrator subtype','path');
kitchenR.set('rays per pixel', 64);
kitchenR.set('fov', 60); % check this
kitchenR.set('filmresolution', [640, 360]); % higher for production

piMaterialsInsert(kitchenR,'names',{'brickwall001'});

ourString = 'tea';

kitchenR = charactersRender(kitchenR, ourString, ...
    'distance', 3, 'material_name','brickwall001', scaleLetter=1);

%idx = piAssetSearch(thisR,'object name','3_O');
%thisR.set('asset',idx,'world position',[0 0 -1]);

%% No lens or omnni camera. Just a pinhole to render a scene radiance

kitcenR.camera = piCameraCreate('pinhole');
%piAssetGeometry(thisR);
piWRS(kitchenR);
