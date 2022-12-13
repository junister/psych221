% Create a virtual eye chart (modified Snellen for now)

% D. Cardinal, Stanford University, December, 2022
% Don't have all letters yet, so content isn't accurate

% clear the decks
ieInit;

%%  Characters and a light

% Eye Chart Parameters
chartDistance = 6; % meters or about 20 feet
baseLetterSize = .02; % .00873; % 8.73mm @ 6 meters, "20/20" vision
rowHeight = 2 * baseLetterSize;
letterSpacing = 3 * baseLetterSize;

topRowHeight = 0; % varies with the scene we use

% effective distance for each row
rowDistances = {60, 42, 24, 12, 6, 3};

% Eye Chart Letters
% NOTE: CURRENTLY CAN'T RE-USE LETTERS
% AND CAN ONLY USE UPPERCASE THROUGH G
rowLetters = {'E', 'FAB', 'CDG', 'abcde', 'fghijk', 'lmnopq'};

% Set Chart parameters

% start with a simple background
% Replace this with a background
thisR = piRecipeCreate('flatSurfaceWhiteTexture');

% Need to set from and to, not sure to what
thisR = recipeSet(thisR, 'from', [0 0 0]);
thisR = recipeSet(thisR, 'to', [0 6.5 0]);

%{
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
%%  Asphalt road material
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
        % Right now we mess up Ucase, so using LCase
        thisR = charactersRender(thisR, rowLetters{ii}(jj));

        % Find the name of our letter object
        if isequal(upper(rowLetters{ii}(jj)), rowLetters{ii}(jj))
            letterObject = ['001_001_' lower(rowLetters{ii}(jj)) '_uc_O'];
        else
            letterObject = ['001_001_' rowLetters{ii}(jj) '_O'];
        end

        thisR.set('asset',letterObject,'material name',letterMaterial);
        thisR.set('asset', letterObject, ...
            'translate', [spaceLetter chartDistance letterVertical]);
        thisR.set('asset',letterObject, ...
            'scale', [letterScale letterScale letterScale]);
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);
