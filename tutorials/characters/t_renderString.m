% Demonstrate rendering a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

% should be incorporated into a function

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
ourString = 'cat';
letterSpacing = .4;

% add letters
for ii = 1:numel(ourString)
    ourLetter = ourString(ii);
    ourLetterAsset = piAssetLoad([ourLetter '-pbrt.mat']);
    piRecipeMerge(thisR, ourLetterAsset.thisR);
    spaceLetter = ii * letterSpacing;
    scaleLetter = 2; % TBD
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