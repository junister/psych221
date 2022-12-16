function outputR = charactersRender(aRecipe, aString, options)
% Render a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

arguments
    aRecipe;
    aString;

    % Optional parameters
    options.letterSpacing = .4;
    options.letterScale = 1; % TBD
    options.letterMaterial = '';
    options.letterPosition = [0 0 0];    

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
piMaterialsInsert(outputR,'groups',{'diffuse'});

% add letters
for ii = 1:numel(aString)
    ourLetter = aString(ii);

    % Addresses non-case-sensitive file sensitive
    if isstrprop(ourLetter, 'alpha') && isequal(upper(ourLetter), ourLetter)
        ourAssetName = [lower(ourLetter) '_uc-pbrt.mat'];
        ourAsset = [lower(ourLetter) '_uc'];
    else
        ourAssetName = [ourLetter '-pbrt.mat'];
        ourAsset = ourLetter;
    end

    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character'); 
    letterRecipe = ourLetterAsset.thisR;
    letterObject = piAssetSearch(letterRecipe,'object name',[ourAsset '_O']);
    
    % location, scale, and material elements
    letterRecipe.set('asset',letterObject,'material name',options.letterMaterial);
    letterRecipe.set('asset', letterObject, ...
        'translate', options.letterPosition);

    % TBD space subsequent letters
    %spaceLetter = (ii-1) * options.letterSpacing;
    %outputR.set('asset', letterNode,'translate', ...
    %    [spaceLetter 0 0]);

    letterRecipe.set('asset',letterObject, ...
        'scale', options.letterScale);

    % maybe we don't always want this?
    % need to make sure we know
    letterRecipe.set('asset',letterObject, 'rotate', [-90 00 0]);

    piRecipeMerge(outputR, ourLetterAsset.thisR);
    
end

