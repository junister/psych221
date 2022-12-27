% Might become a way to render specific characters on a background
% in preparation to reconstruction and scoring
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Something still isn't quite right about the H and I assets
Alphabet_UC = 'ABCDEFGJKLMNOPQRSTUVWXYZ';
Alphabet_LC = 'abcdefghijklmnopqrstuvwxyz';
Digits = '0123456789';
testChars = 'D'; % just a few for debugging

humanEye = ~piCamBio(); % if using ISETBio, then use human eye

% Start with a "generic" recipe
[thisR, ourMaterials, ourBackground] = prepRecipe('flashCards');

% now we want to make the scene FOV 1 degree
% I think we need a camera first
thisR.camera = piCameraCreate('pinhole');
thisR.recipeSet('fov', 50/60); % 50 arc-minutes is enough for 200/20 

% set our film to a square
filmSideLength = 240;
recipeSet(thisR, 'film resolution', [filmSideLength filmSideLength]);

% We've set our scene to be 1 degree (60 arc-minutes) @ 6 meters
% For 20/20 vision characters should be .00873 meters high (5 arc-minutes)
% For 200/20 they are 50 arc-minutes (or .0873 meters high)
% EXCEPT our Assets include blank backgrounds (Sigh)
% Note that letter size is per our Blender assets which are l w h, 
% NOT x, y, z
charMultiple = 10; % how many times the 20/20 version
charBaseline = .00873;
charSize = charMultiple * charBaseline;

% and drop the character by half its size
charactersRender(thisR,testChars,'letterSize',[charSize .02 charSize], ...
    letterPosition=[0 -1*(charSize/2) 6]); % 6 Meters out

piWRS(thisR);
%thisR.birdsEye();

%% ------------- Support Functions Start Here

function addMaterials(thisR)

% See list of materials, if we want to select some
allMaterials = piMaterialPresets('list', [],'show',false);

% Loop through our material list, adding whichever ones work
for iii = 1:numel(allMaterials)
    try
        piMaterialsInsert(thisR, 'names',allMaterials{iii});
    catch
        warning('Material: %s insert failed. \n',allMaterials{ii});
    end
end
end

function [thisR, ourMaterials, ourBackground] = prepRecipe(sceneName)

thisR = piRecipeDefault('scene name',sceneName);
thisR = addLight(thisR);


addMaterials(thisR);
ourMaterialsMap = thisR.get('materials');
ourMaterials = values(ourMaterialsMap);

recipeSet(thisR,'to',[0 .01 10]);

% set vertical to 0. -6 gives us 6m or 20 feet
recipeSet(thisR,'from',[0 .01 -6]);

% Now set the place/color of the background
ourBackground = piAssetSearch(thisR,'object name', 'flashCard_O');
% background is at 0 0 0 by default
piAssetTranslate(thisR,ourBackground,[0 .01 10]); % just behind center

end


function thisR = addLight(thisR)
spectrumScale = 1;
lightSpectrum = 'equalEnergy';
lgt = piLightCreate('scene light',...
    'type', 'distant',...
    'specscale float', spectrumScale,...
    'spd spectrum', lightSpectrum,...
    'from', [0 0 0],  'to', [0 0 20]);
thisR.set('light', lgt, 'add');

end
