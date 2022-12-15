function outputR = charactersRender(aRecipe, aString, options)
% Render a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

arguments
    aRecipe;
    aString;

    % Optional parameters
    options.letterSpacing = .4;
    options.scaleLetter = 4; % TBD
    options.material_name = '';
    options.distance = 6; % default in meters
    
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

    % REQUIRES CASE SENSITIVE FILE SYSTEM
    if isstrprop(ourLetter, 'alpha') && isequal(upper(ourLetter), ourLetter)
        ourAssetName = [lower(ourLetter) '_uc-pbrt.mat'];
        ourAsset = [lower(ourLetter) '_uc'];
    else
        ourAssetName = [ourLetter '-pbrt.mat'];
        ourAsset = ourLetter;
    end
    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character');

    ourLetterAsset.thisR.set('object distance', options.distance);
    
    letterNode = ['001_001_' ourAsset '_O'];

    piRecipeMerge(outputR, ourLetterAsset.thisR);

    if ~isempty(options.material_name)  
        outputR.set('asset',letterNode, 'material name', options.material_name);
    end

    outputR.set('asset', letterNode, 'scale', ...
        [options.scaleLetter options.scaleLetter options.scaleLetter]);

    % maybe we don't always want this?
    %outputR.set('asset',letterNode, 'rotate', [-90 00 0]);

    % space the letters
    spaceLetter = (ii-1) * options.letterSpacing;
    outputR.set('asset', letterNode,'translate', ...
        [spaceLetter 0 0]);
    
end

