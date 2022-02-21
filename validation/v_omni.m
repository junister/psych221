% Verify that omni camera is working
%
% D. Cardinal, Feb, 2022
%
ieInit;
thisR = piRecipeDefault('scene name','cornell box');


lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

% compare pinhole with omni default and omni lens
thisR.camera = piCameraCreate('pinhole'); 
piWRS(thisR);

thisR.camera = piCameraCreate('omni');
recipeSet(thisR,'lights', ourLight,'add');
piWRS(thisR);

thisR.camera = piCameraCreate('omni', 'lensFile','dgauss.22deg.3.0mm.json');
recipeSet(thisR,'lights', ourLight,'add');
piWRS(thisR);



