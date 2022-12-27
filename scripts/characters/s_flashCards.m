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
thisR = piRecipeCreate('MacBethChecker');
[thisR, ourMaterials, ourBackground] = prepRecipe(thisR); % add light, move stuff around, etc.

% now we want to make the scene FOV 1 degree
% I think we need a camera first
thisR.camera = piCameraCreate('pinhole');
thisR.recipeSet('fov', 1); % 1

% We've set our scene to be 1 degree (60 arc-minutes) @ 6 meters
% For 20/20 vision characters should be .00873 meters high (5 arc-minutes)
% For 200/20 they are 50 arc-minutes (or .0873 meters high)
% EXCEPT our Assets include blank backgrounds (Sigh)
% Note that letter size is per our Blender assets which are l w h, 
% NOT x, y, z
charMultiple = 10; % how many times the 20/20 version
charBaseline = .0873;
charSize = charMultiple * charBaseline;

charactersRender(thisR,testChars,'letterSize',[charSize .02 charSize], ...
    letterPosition=[0 charSize/10 0]); % 6 Meters out

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

function [thisR, ourMaterials, ourBackground] = prepRecipe(thisR)

% The long way around to getting a simple background
% Someday I'll learn how to do it right -djc

for ii = 24:-1:1 % number of patches -- backwards as they re-number
    try
        ourAsset = 0; % reset
        if ii < 9
            ourAsset = piAssetSearch(thisR,'object name',['00' num2str(ii+1) '_colorChecker_O']);
        else
            ourAsset = piAssetSearch(thisR,'object name',['0' num2str(ii+1) '_colorChecker_O']);
        end
        % don't delete blank asset by default
        % And deleteing a bunch of assets confuses the tree,
        % so maybe just teleport them to Mars?
        if ourAsset > 0, piAssetTranslate(thisR, ourAsset, [100 100 100]); end
    catch EX
        warning('Failed to delete asset %s. \n',ii, EX.message);
    end
end

addMaterials(thisR);
ourMaterialsMap = thisR.get('materials');
ourMaterials = values(ourMaterialsMap);

recipeSet(thisR,'to',[0 .01 10]);

% set vertical to 0. -6 gives us 6m or 20 feet
recipeSet(thisR,'from',[0 .01 -6]);

% Now set the color of the background
ourBackground = piAssetSearch(thisR,'object name', '001_colorChecker_O');
% background is at 0 0 0 by default
%piAssetTranslate(thisR,ourBackground,[0 0 1]); % just behind center
end

% Not needed for MCC
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
