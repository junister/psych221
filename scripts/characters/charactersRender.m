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

% Set output recipe to our initial input
outputR = aRecipe;

% Note TBD -- Uppercase requires special handling since those
%         recipes need a different name to avoid case collision

% add letters
for ii = 1:numel(aString)
    ourLetter = aString(ii);
    ourLetterAsset = piAssetLoad([ourLetter '-pbrt.mat']);

    ourLetterAsset.thisR.set('object distance', options.distance);
    
    letterNode = ['001_001_' ourLetter '_O'];
    % We have an issue with merge nodes not working correctly!

    piRecipeMerge(outputR, ourLetterAsset.thisR);

    outputR.set('asset',letterNode, 'material name', options.material_name);

    outputR.set('asset', letterNode, 'scale', ...
        [options.scaleLetter options.scaleLetter options.scaleLetter]);

    % space the letters
    spaceLetter = ii * options.letterSpacing;
    outputR.set('asset', letterNode,'translate', ...
        [spaceLetter 0 0]);
    
end

