% Might become a way to render specific characters on a background
% in preparation to reconstruction and scoring
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Something still isn't quite right about the H and I assets
% Small d also appears broken
Alphabet_UC = 'ABCDEFGJKLMNOPQRSTUVWXYZ';
Alphabet_LC = 'abcefghijklmnopqrstuvwxyz';
Digits = '0123456789';
allCharacters = [Alphabet_LC Alphabet_UC Digits];

testChars = 'D'; % just a few for debugging

% not always true. Sometimes we want film for the scene
%humanEye = ~piCamBio(); % if using ISETBio, then use human eye

% Start with a "generic" recipe that has a light
% and whatever materials we can load
[thisR, ourMaterials, ourBackground] = prepRecipe('flashCards');

% now we want to make the scene FOV 1 degree
% I think we need a camera first
thisR.camera = piCameraCreate('pinhole');
thisR.recipeSet('fov', 1); % 50 arc-minutes is enough for 200/20

% NOTE: We may not allow for any "padding" that is in the character
%       assets, around the edges of the actual character.

% Set quality parameters
% High-fidelity
thisR.set('rays per pixel',1024);
% Normal-fidelity
thisR.set('rays per pixel',256);

% set our film to a square, like the characters on an eye chart
% and to mimic the fovea area later on
filmSideLength = 240;
recipeSet(thisR, 'film resolution', [filmSideLength filmSideLength]);

% We've set our scene to be 1 degree (60 arc-minutes) @ 6 meters
% For 20/20 vision characters should be .00873 meters high (5 arc-minutes)
% For 200/20 they are 50 arc-minutes (or .0873 meters high)
% Note that letter size is per our Blender assets which are l w h,
% NOT x, y, z

% We will want to iterate over the charMultiple
% once we get this working for one multiple
charMultiple = 10; % 10; % how many times the 20/20 version

charBaseline = .00873; % 20/20 @ 6 meters
charSize = charMultiple * charBaseline;

% and lower the character position by half its size
%{
% for testing
charactersRender(thisR,testChars,'letterSize',[charSize .02 charSize], ...
    letterPosition=[0 -1*(charSize/2) 6]); % 6 Meters out
%}
% Now generate a full set of flash cards with black background

% Can run one of the three, but maybe not all at once?
% Eventually we will concatenate or iterate through them
useCharset = Digits; % Works
%useCharset = Alphabet_UC; % Works
%useCharset = Alphabet_LC; % Works

numMat = 0; % keep track of iterating through our materials
for ii = 1:numel(useCharset)

    % also need to set material for letter
    numMat = numMat+ 1;
    useMat = ourMaterials{mod(numMat, numel(ourMaterials))};

    % from winds up at -6, so we need to offset
    wereAt = recipeGet(thisR,'from');
    charactersRender(thisR,useCharset(ii), 'letterSize',[charSize .02 charSize], ...
        'letterPosition',[0 -1*(charSize/2), 6] + wereAt, ...
        'letterMaterial', useMat);
end

% obj is either a scene, or an oi if we use optics
[obj] = piWRS(thisR);

% Needs more params:)
%charSampleCreate(obj, thisR); % figure out what we want here

%% ------------- Support Functions Start Here
%%

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

% Give it a skylight (assumes we want one)
thisR.set('skymap','sky-sunlight.exr');

addMaterials(thisR);
ourMaterialsMap = thisR.get('materials');
ourMaterials = keys(ourMaterialsMap);

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



