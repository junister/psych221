% Verify that omni camera is working
%
% D. Cardinal, Feb, 2022
%
ieInit;
thisR = piRecipeDefault('scene name','cornell box');

thisR.camera = piCameraCreate('omni', 'lensFile','dgauss.22deg.3.0mm.json');

lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');
piWRS(thisR);


