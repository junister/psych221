% Create a virtual eye chart (modified Snellen for now)

% D. Cardinal, Stanford University, December, 2022
% Don't have all letters yet, so content isn't accurate

% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Characters and a light

% Eye Chart Parameters
% If we want to 0-base we need to align elements
sceneFrom = -1; % arbitrary based on background 
sceneTo = 8;

chartDistance = 6; % 6 meters from camera or about 20 feet
chartPlacement = sceneFrom + chartDistance;

% 20/20 is 5 arc-minutes per character, 1 arc-minute per feature
% at 20 feet that is 8.73mm character height.
baseLetterSize = .00873; % 8.73mm @ 6 meters, "20/20" vision
rowHeight = 10 * baseLetterSize;
letterSpacing = 6 * baseLetterSize;

topRowHeight = 1.2; % varies with the scene we use

% effective distance for each row
% need to magnify by a ratio
% 60 = 200/20, etc. 6 is 20/20 (currently Row 5)
rowDistances = {60, 42, 24, 12, 6, 3};

% Eye Chart Letters
% Vocabulary of Snellen Letters
% C, D, E, F, L, O, P, T, and Z
% One typical chart arrangement
% 'E', 'F P', 'T O Z', 'L P E D', "P E C F D', 'E D F C Z P', ...
% 'F E L O Z P D', 'D E F P O T E C'

% NOTE: CURRENTLY CAN'T RE-USE LETTERS
% Can test multi-letters by using '00'
%rowLetters = {'00', 'E', 'TUV', 'CDGOP', 'RZMNQSWX', 'ABFJKLY'};
rowLetters = {'E', 'FP', 'TOZ', 'LpeD', '0qCfd',};

%% Create our scene starting with a simple background
%thisR = piRecipeCreate('MacBethChecker');
thisR = piRecipeCreate('flatsurface');
thisR = piMaterialsInsert(thisR,'names',{'glossy-black'});

% fix defaults with our values
thisR.set('rays per pixel', 32);
% resolution notes:
% Meta says 8K needed for readable 20/20
% Current consumer displays are mostly 1440 or 2k
% High-end might be 4K (these are all per eye)
thisR.set('filmresolution', [1280, 720]);

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

% Get materials we might need
% white on black for now, need to swap
%mattewhite = piMaterialCreate('matteWhite', 'type', 'coateddiffuse');
%thisR = thisR.set('material', 'add', mattewhite);
%letterMaterial = 'mattewhite'; % substitute for black
letterMaterial = 'glossy-black'; % substitute for black

% add letters by row
for ii = 1:numel(rowLetters)
    
    % Handle placement and scale for each row
    letterScale = (rowDistances{ii}/chartDistance) * baseLetterSize;
    letterVertical = topRowHeight - (ii-1) * rowHeight;

    ourRow = rowLetters{ii};

    for jj = 1:numel(rowLetters{ii})
       
        spaceLetter = (jj - ceil(numel(rowLetters{ii})/2)) * letterSpacing;

        % Assume y is vertical and z is depth (not always true)
        letterPosition = [spaceLetter letterVertical chartPlacement];

        % Need to decide on the object node name to merge
        thisR = charactersRender(thisR, rowLetters{ii}(jj), ...
            'letterScale', [letterScale letterScale letterScale], ...
            'letterSpacing', [letterSpacing letterVertical chartDistance], ...
            'letterMaterial', letterMaterial,...
            'letterPosition', letterPosition);
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance


%thisR.camera = piCameraCreate('pinhole');

% want a narrow FOV for the distance we're using
% can only set once we have a pinhole camera
thisR = thisR.set('fov',28);

% For human eye optics with ISETbio we can use something like
% oi = oiCreate('wvf human'); % then oiCompute

% Is there anything we can do at the PBRT stage?
% Right now our current build of pbrt doesn't seem to work with human eye
%thisR.camera = piCameraCreate('human eye'); 

% Use a pinhole for now
thisR.camera = piCameraCreate('pinhole');

piWRS(thisR);
