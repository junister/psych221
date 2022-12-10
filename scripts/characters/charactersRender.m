function charactersRender(aRecipe, aString, options)
% Render a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

arguments
    aRecipe = '';
    aString = '';

    % ASPIRATIONAL / TBD
    options.fontSize = 12;
    options.fontColor = 'white';
    options.material = 'coateddiffuse';
    
end
% For now we can use a background scene
% When we make this a function we'll have to sort out defaults
thisR = piRecipeDefault; % MCC

% characters (and default recipe) don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');

% Note -- Uppercase requires special handling since those
%         recipes need a different name to avoid case collision
ourString = 'c';
letterSpacing = .4;

% add letters
for ii = 1:numel(ourString)
    ourLetter = ourString(ii);
    ourLetterAsset = piAssetLoad([ourLetter '-pbrt.mat']);
    % We have an issue with merge nodes not working correctly!
    piRecipeMerge(thisR, ourLetterAsset.thisR);
    spaceLetter = ii * letterSpacing;
    scaleLetter = 1; % TBD
    thisR.set('asset',['001_001_' ourLetter '_O'],'scale', ...
        [scaleLetter scaleLetter scaleLetter]);
    
    % take out to simply for debugging
    %thisR.set('asset',['001_001_' ourLetter '_O'],'move to', [spaceLetter 0 0]);
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

%thisR.set('object distance',2);
%thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);