% Demonstrate rendering a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

% should be incorporated into a function

% For now we can use a background scene
% When we make this a function we'll have to sort out defaults
thisR = piRecipeDefault; % MCC

% characters (and default recipe) don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

% do we need to insert the material or can charactersRender
% try to do that for us?
piMaterialsInsert(thisR,'name','brickwall001');

ourString = 'cat';

thisR = charactersRender(thisR, ourString, 'material_name','brickwall001', ...
    'distance', .5);

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);