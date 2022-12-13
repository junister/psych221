% Create a virtual eye chart

% D. Cardinal, Stanford University, December, 2022
% VAGUE OUTLINE ONLY SO FAR

% clear the decks
ieInit;

%%  Characters and a light

% start with a simple 1 in the middle
thisR = piRead('1-pbrt.pbrt');


% characters don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');
%piWRS(thisR);

% Get materials we might need
mattewhite = piMaterialCreate('matteWhite', 'type', 'coateddiffuse');
thisR.set('material', 'add', mattewhite);

% Set Chart parameters
topRowHeight = 1;
letterSpacing = .9;
scaleFactor = .7; % need to figure this out for real
rowHeight = 1; % guess

% Generate letters
chartRows = {'E', 'FAB', 'CDG'};

% add letters
for ii = 1:numel(chartRows)
    
    % Handle placement and scale for each row
    letterScale = scaleFactor^ii;
    letterVertical = topRowHeight - (ii-1) * rowHeight;
    ourRow = chartRows{ii};

    for jj = 1:numel(chartRows{ii})
       
        spaceLetter = (jj - ceil(numel(chartRows{ii}/2))) * letterSpacing;
        % Need to decide on the object node name to merge
        % Right now we mess up Ucase, so using LCase
        thisR = charactersRender(thisR, chartRows{ii}(jj));

        thisR.set('asset',['001_001_' lower(chartRows{ii}(jj)) '_uc_O'], ...
            'translate', [spaceLetter letterVertical letterVertical]);
        thisR.set('asset',['001_001_' lower(chartRows{ii}(jj)) '_uc_O'], ...
            'scale', [letterScale letterScale letterScale]);
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.set('object distance',20);
thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);
