%%  Character and light
thisR = piRead('1-pbrt.pbrt');

% characters don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.set('object distance',1);
thisR.camera = piCameraCreate('pinhole'); 
piWRS(thisR);
