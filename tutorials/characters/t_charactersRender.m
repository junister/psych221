% Demonstrate rendering a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

% Ue a background scene
thisR = piRecipeDefault; % MCC
thisR.set('object distance', 2);

% characters (and default recipe) don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

% do we need to insert the material or can charactersRender
% try to do that for us?
piMaterialsInsert(thisR,'names',{'brickwall001'});

% mcc already has these
% piMaterialsInsert(thisR,'names',{'diffuse-red'});

%% Limitations:
% If we have a duplicate letter, not handled yet
% Upper case also doesn't work as piRead changes the node to lower case
ourString = '3';

%  'material_name','brickwall001',
thisR = charactersRender(thisR, ourString, ...
    'distance', 15, 'material_name','diffuse-red', scaleLetter=3);

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);