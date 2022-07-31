% Verify that omni camera is working
%
% D. Cardinal, Feb, 2022
%

%% Initialize

ieInit;
thisR = piRecipeDefault('scene name','cornell box');

%% Create a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

%% compare pinhole with omni default and omni lens
thisR.camera = piCameraCreate('pinhole'); 
piWRS(thisR);

%% Omni default
thisR.camera = piCameraCreate('omni');
recipeSet(thisR,'lights', ourLight,'add');
piWRS(thisR);

%% Omni with specified lens
thisR.camera = piCameraCreate('omni', 'lensFile','dgauss.22deg.3.0mm.json');
recipeSet(thisR,'lights', ourLight,'add');
piWRS(thisR);

%% END



