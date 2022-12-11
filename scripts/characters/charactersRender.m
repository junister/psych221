function outputR = charactersRender(aRecipe, aString, options)
% Render a string from our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

arguments
    aRecipe;
    aString;

    % Optional parameters
    options.letterSpacing = .4;
    options.scaleLetter = 1; % TBD
    options.material_name = 'coateddiffuse';
    options.distance = 5; % in meters
    
    % ASPIRATIONAL / TBD
    options.fontSize = 12;
    options.fontColor = 'white';
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

    % check for Upper Case letter (assets need a different name to avoid
    % case collision)
    if isstrprop(ourLetter, 'alpha') && isequal(upper(ourLetter), ourLetter)
        ourAssetName = [ourLetter '-pbrt-UC.mat'];
    else
        ourAssetName = [ourLetter '-pbrt.mat'];
    end
    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character');

    ourLetterAsset.thisR.set('object distance', options.distance);
    
    letterNode = ['001_001_' ourLetter '_O'];
    % We have an issue with merge nodes not working correctly!

    piRecipeMerge(outputR, ourLetterAsset.thisR);

    outputR.set('asset',letterNode, 'material name', options.material_name);

    outputR.set('asset', letterNode, 'scale', ...
        [options.scaleLetter options.scaleLetter options.scaleLetter]);

    % space the letters
    spaceLetter = (ii-1) * options.letterSpacing;
    outputR.set('asset', letterNode,'translate', ...
        [spaceLetter 0 0]);
    
end

