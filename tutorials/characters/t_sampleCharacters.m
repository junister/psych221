%%  Character and light
thisR = piRead('1-pbrt.pbrt');

% characters don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

%% No lens or omnni camera. Just a pinhole to render a scene radiance

piMaterialsInsert(thisR,'name','brickwall001');
thisR.set('object distance',1);
thisR.camera = piCameraCreate('pinhole'); 
thisR.set('asset','001_001_1_O','material name','brickwall001');
piAssetGeometry(thisR);
piWRS(thisR);
