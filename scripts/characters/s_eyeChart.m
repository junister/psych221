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

% Try to add a coordinate legend to help see what's up
coordinates = piAssetLoad('coordinate.mat');
piRecipeMerge(thisR, coordinates.thisR);

% not sure why this fails, maybe need to name asset it vs. name
% we should probably use assetsearch()!
%{
% if we can get an xyz set of "arrows" somehow
ourX = piAssetSearch(thisR,'object name', 'x_O');
thisR.set('asset',ourX, ...
    'translate', [0 0 0]);
ourY = piAssetSearch(thisR,'object name', 'y_O');
thisR.set('asset',ourY, ...
    'translate', [0 0 0]);
ourZ = piAssetSearch(thisR,'object name', 'z_O');
thisR.set('asset',ourZ, ...
    'translate', [0 0 0]);
%}

% Set Chart parameters
topRowHeight = 1;
letterSpacing = .9;
scaleFactor = .7; % need to figure this out for real
rowHeight = 2; % guess

% Generate letters
chartRows = {'E', 'FAB', 'CDG'};

% add letters
for ii = 1:numel(chartRows)
    
    % Handle placement and scale for each row
    letterScale = scaleFactor * ii;
    letterVertical = topRowHeight - (ii-1) * rowHeight;
    ourRow = chartRows{ii};

    for jj = 1:numel(chartRows{ii})
       
        spaceLetter = (jj - ceil(numel(chartRows{ii}/2))) * letterSpacing;
        % Need to decide on the object node name to merge
        % Right now we mess up Ucase, so using LCase
        thisR = charactersRender(thisR, chartRows{ii}(jj));

        thisR.set('asset',['001_001_' lower(chartRows{ii}(jj)) '_uc_O'], ...
            'translate', [spaceLetter letterVertical letterVertical]);
    end
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.set('object distance',20);
thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);
