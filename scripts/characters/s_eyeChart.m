% Create a virtual eye chart (modified Snellen for now)

% D. Cardinal, Stanford University, December, 2022
% Don't have all letters yet, so content isn't accurate

% clear the decks
ieInit;

%%  Characters and a light

% Eye Chart Parameters
% If we want to 0-base we need to align elements
sceneFrom = -1; % arbitrary based on background 
sceneTo = 8;

chartDistance = 6; % 6 meters from camera or about 20 feet
chartPlacement = sceneFrom + chartDistance;

% 20/20 is 5 arc-minutes per character, 1 arc-minute per feature
% PS I never noticed that when getting an eye exam. Look next time!
% at 20 feet that is 8.73mm per character.
baseLetterSize = .00873; % 8.73mm @ 6 meters, "20/20" vision
rowHeight = 2 * baseLetterSize;
letterSpacing = 3 * baseLetterSize;

topRowHeight = 1; % varies with the scene we use

% effective distance for each row
% need to magnify by a ratio
% 60 = 200/20, etc.
rowDistances = {60, 42, 24, 12, 6, 3};

% Eye Chart Letters
% NOTE: CURRENTLY CAN'T RE-USE LETTERS
% AND CAN ONLY USE UPPERCASE THROUGH G
rowLetters = {'E', 'FAB', 'CDG', 'abcde', 'fghijk', 'lmnopq'};

% start with a simple background
% Replace this with a background
thisR = piRecipeCreate('MacBethChecker');

% Set our visual "box"
thisR = recipeSet(thisR, 'up', [0 1 0]);
thisR = recipeSet(thisR, 'from', [0 0 sceneFrom]);
thisR = recipeSet(thisR, 'to', [0 0 sceneTo]);

% checker is at 0 depth here, so we want to move it behind the eye chart
% which will be at from + 6. So we try to move it to from + 8
checkerAssets = piAssetSearch(thisR, 'object name', 'colorChecker_O');
for ii = 1:numel(checkerAssets)
    piAssetTranslate(thisR, checkerAssets(ii), ...
        [0 0 chartPlacement + 2]);
end

% in case we need to delete an asset
%origin = piAssetSearch(thisR,'object name','origin_O');
%thisR = recipeSet(thisR,'asset',origin,'delete');
%piWRS(thisR);


%{
% this is now done by RecipeCreate when we use that instead of Load
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');
%}
%piWRS(thisR);

% Get materials we might need
% white on black for now, need to swap
mattewhite = piMaterialCreate('matteWhite', 'type', 'coateddiffuse');
thisR = thisR.set('material', 'add', mattewhite);

% to get glossy-black, but doesn't work
%thisR = piMaterialsInsert(thisR,'groups',{'glossy'});

%try a different material
%piMaterialsInsert(thisR,'groups','diffuselist');
letterMaterial = 'mattewhite'; % substitute for black

% add letters by row
for ii = 1:numel(rowLetters)
    
    % Handle placement and scale for each row
    letterScale = (rowDistances{ii}/chartDistance) * baseLetterSize;
    letterVertical = topRowHeight - (ii-1) * rowHeight;

    % Assume y is vertical and z is depth (not always true)
    letterPosition = [0 letterVertical chartPlacement];
    ourRow = rowLetters{ii};

    for jj = 1:numel(rowLetters{ii})
       
        spaceLetter = (jj - ceil(numel(rowLetters{ii}/2))) * letterSpacing;

        % Need to decide on the object node name to merge
        thisR = charactersRender(thisR, rowLetters{ii}(jj), ...
            'letterScale', [letterScale letterScale letterScale], ...
            'letterSpacing', [letterSpacing letterVertical chartDistance], ...
            'letterMaterial', letterMaterial,...
            'letterPosition', letterPosition);

        % Find the name of our letter object
        % possibly just use the final portion & then assetSearch()
        if isequal(upper(rowLetters{ii}(jj)), rowLetters{ii}(jj))
            letterObject = ['001_001_' lower(rowLetters{ii}(jj)) '_uc_O'];
        else
            letterObject = ['001_001_' rowLetters{ii}(jj) '_O'];
        end
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole');
% Need to figure out how to set FOV to get better scaling

% Eventually want to move to human eye optics for PBRT
%thisR.camera = piCameraCreate('human eye'); 
%piAssetGeometry(thisR);
piWRS(thisR);
