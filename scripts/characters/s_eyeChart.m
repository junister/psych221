% Create a virtual eye chart (modified Snellen for now)

% D. Cardinal, Stanford University, December, 2022
% Don't have all letters yet, so content isn't accurate

% clear the decks
ieInit;

%%  Characters and a light

% Eye Chart Parameters
chartDistance = 6; % meters or about 20 feet
% 20/20 is 5 arc-minutes per character, 1 arc-minute per feature
% PS I never noticed that when getting an eye exam. Look next time!
% at 20 feet that is 8.73mm per character.
baseLetterSize = .00873; % 8.73mm @ 6 meters, "20/20" vision
rowHeight = 2 * baseLetterSize;
letterSpacing = 3 * baseLetterSize;

topRowHeight = 0; % varies with the scene we use

% effective distance for each row
% need to magnify by a ratio
% 60 = 200/20, etc.
rowDistances = {60, 42, 24, 12, 6, 3};

% Eye Chart Letters
% NOTE: CURRENTLY CAN'T RE-USE LETTERS
% AND CAN ONLY USE UPPERCASE THROUGH G
rowLetters = {'E', 'FAB', 'CDG', 'abcde', 'fghijk', 'lmnopq'};

% Set Chart parameters

% start with a simple background
% Replace this with a background
%thisR = piRecipeCreate('flatSurfaceWhiteTexture');
thisR = piRecipeCreate('MacBethChecker');

% in case we need to delete an asset
%origin = piAssetSearch(thisR,'object name','origin_O');
%thisR = recipeSet(thisR,'asset',origin,'delete');
piWRS(thisR);

% Need to set from and to, not sure to what
thisR = recipeSet(thisR, 'from', [0 0 0]);
thisR = recipeSet(thisR, 'to', [0 0 6.5]);

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
%%  Asphalt road material -- a popular choice for the construction industry:)
piMaterialsInsert(thisR,'name','asphalt-uniform');
letterMaterial = 'asphalt-uniform';

% add letters by row
for ii = 1:numel(rowLetters)
    
    % Handle placement and scale for each row
    letterScale = (rowDistances{ii}/chartDistance) * baseLetterSize;
    letterVertical = topRowHeight - (ii-1) * rowHeight;
    ourRow = rowLetters{ii};

    for jj = 1:numel(rowLetters{ii})
       
        spaceLetter = (jj - ceil(numel(rowLetters{ii}/2))) * letterSpacing;

        % Need to decide on the object node name to merge
        thisR = charactersRender(thisR, rowLetters{ii}(jj));

        % Find the name of our letter object
        % possibly just use the final portion & then assetSearch()
        if isequal(upper(rowLetters{ii}(jj)), rowLetters{ii}(jj))
            letterObject = ['001_001_' lower(rowLetters{ii}(jj)) '_uc_O'];
        else
            letterObject = ['001_001_' rowLetters{ii}(jj) '_O'];
        end

        % We can/should probably pass these as parameters to charactersRender
        % rather than do the edits here, once the dust settles
        thisR.set('asset',letterObject,'material name',letterMaterial);
        thisR.set('asset', letterObject, ...
            'translate', [spaceLetter letterVertical chartDistance]);
        thisR.set('asset',letterObject, ...
            'scale', [letterScale letterScale letterScale]);
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole');
% Need to figure out how to set FOV to get better scaling

% Eventually want to move to human eye optics for PBRT
%thisR.camera = piCameraCreate('human eye'); 
%piAssetGeometry(thisR);
piWRS(thisR);
