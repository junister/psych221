function outputR = charactersRender(aRecipe, aString, options)
% Render a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

arguments
    aRecipe; % recipe where we'll add the characters
    aString; % one or more characters to add to the recipe

    % Optional parameters
    options.letterSpacing = .4;
    options.letterMaterial = '';
    options.letterPosition = [0 0 0];
    options.letterRotation = [0 0 0];
    options.letterSize = [];

    % ASPIRATIONAL / TBD
    options.fontSize = 12;
    options.fontColor = 'black';
    options.direction = 'horizontal_lr';
    options.billboard = false; % whether to have a background box

end

%-----------------------------------------------------------------
% NOTE: We don't handle strings with duplicate characters yet
%       We need to create Instances for subsequent ones, I think!
%-----------------------------------------------------------------

% Set output recipe to our initial input
outputR = aRecipe;
%piMaterialsInsert(outputR,'groups',{'diffuse'});

% Allows for testing duplicate characters by using '00' as the string
gotZero = false;

% Our Blender-rendered Characters [width height depth] 
% Per Matlab these are [l w h]
characterAssetSize = [.88 .25 1.23];

%% add letters
for ii = 1:numel(aString)
    ourLetter = aString(ii);

    % Addresses non-case-sensitive file systems
    % by using _uc to denote Uppercase letter assets
    if isstrprop(ourLetter, 'alpha') && isequal(upper(ourLetter), ourLetter)
        ourAssetName = [lower(ourLetter) '_uc-pbrt.mat'];
        ourAsset = [lower(ourLetter) '_uc'];
    else
        % TEST TO SEE IF WE CAN DUPLICATE ASSETS
        if isequal(ourLetter,'0')
            if gotZero == false
                gotZero = true;
                ourAssetName = [ourLetter '-pbrt.mat'];
                ourAsset = ourLetter;
            else
                ourAssetName = '0-pbrt-1.mat';
                ourAsset = ourLetter;
            end
        else
            % This is the normal case
            ourAssetName = [ourLetter '-pbrt.mat'];
            ourAsset = ourLetter;
        end
    end

    %% Load our letter asset
    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character'); 
    
    letterObject = piAssetSearch(ourLetterAsset.thisR,'object name',[ourAsset '_O']);
    
    % location, scale, and material elements
    if ~isempty(options.letterMaterial)
        ourLetterAsset.thisR = ourLetterAsset.thisR.set('asset',letterObject,'material name',options.letterMaterial);
    end

    ourLetterAsset.thisR = ourLetterAsset.thisR.set('asset', letterObject, ...
        'rotate', options.letterRotation);

    % TBD space subsequent letters
    %spaceLetter = (ii-1) * options.letterSpacing;
    %outputR.set('asset', letterNode,'translate', ...
    %    [spaceLetter 0 0]);

    % We want to scale by our characterSize compared with the desired size
    if ~isempty(options.letterSize)
        letterScale = options.letterSize ./ characterAssetSize;
        ourLetterAsset.thisR.set('asset',letterObject, ...
            'scale', letterScale);
    end

    % maybe we don't always want this?
    % need to make sure we know
    ourLetterAsset.thisR.set('asset',letterObject, 'rotate', [-90 00 0]);
    
    % translate goes after scale or scale will reduce translation
    ourLetterAsset.thisR = ourLetterAsset.thisR.set('asset', letterObject, ...
        'translate', options.letterPosition);



    outputR = piRecipeMerge(outputR, ourLetterAsset.thisR, 'node name', ourLetterAsset.mergeNode);
    
end

