function outputR = charactersRender(aRecipe, aString, options)
% Add a string of character assets to a recipe
%
% Synopsis
%   outputR = charactersRender(aRecipe, aString, options)
%
% Description
%   Loads the characters saved in the ISET3d assets file for
%   characters, and merges them into the input recipe.  Requires
%   ISET3d and ISETCam.  Used by ISETauto, and ISETonline
%
% Input
%  aRecipe
%  aString
%
% Options (key/val pairs)
%  letterSpacing
%  letterMaterial
%  letterPosition
%  letterRotation
%  letterSize
%
% Output
%  outputR - Modified recipe
%
% D. Cardinal, Stanford University, December, 2022
%
% See also
%  ISETauto and ISETonline
%

% Example:
%{
 thisR = piRecipeCreate('macbeth checker');
 to = thisR.get('to') - [0.5 0 -0.8];
 delta = [0.15 0 0];
 for ii=1:numel('Lorem'), pos(ii,:) = to + ii*delta; end
 pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
 thisR = charactersRender(thisR, 'Lorem','letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],'letterPosition',pos,'letterMaterial','wood-light-large-grain');
 thisR.set('skymap','sky-sunlight.exr');
 thisR.set('nbounces',4);
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell_Box');
 thisR.set('film resolution',[384 256]*2);
 to = thisR.get('to') - [0.35 -0.1 -0.8];
 delta = [0.14 0 0];
 for ii=1:numel('Ipsum'), pos(ii,:) = to + ii*delta; end
 pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
 thisR = charactersRender(thisR, 'Lorem','letterSize',[0.10,0.1,0.15],'letterRotation',[0,15,15],'letterPosition',pos,'letterMaterial','checkerboard');
 thisR.set('skymap','sky-sunlight.exr');
 thisR.set('nbounces',4);
 piWRS(thisR);
%}

%%
arguments
    aRecipe; % recipe where we'll add the characters
    aString; % one or more characters to add to the recipe

    % Optional parameters
    options.letterSpacing = .4;
    options.letterMaterial = '';
    options.letterPosition = [0 0 0];  % Meters
    options.letterRotation = [0 0 0];  % Degrees
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

if size(options.letterPosition,1) == 1
    letterPosition = repmat(options.letterPosition,5,1);
end

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

    %% Load letter assets

    % This should only happen once, right?
    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character'); 
    
    letterObject = piAssetSearch(ourLetterAsset.thisR,'object name',[ourAsset '_O']);
    
    % location, scale, and material elements
    if ~isempty(options.letterMaterial)
        piMaterialsInsert(ourLetterAsset.thisR,'names',{options.letterMaterial});
        ourLetterAsset.thisR = ourLetterAsset.thisR.set('asset',letterObject,'material name',options.letterMaterial);
    end

    ourLetterAsset.thisR = ourLetterAsset.thisR.set('asset', letterObject, ...
        'rotate', options.letterRotation);

    % Is it set the position?  Or is it set the spacing?
    %{
    % Space after each letter subsequent letters
    if ii > 1
        % Starting with the 2nd letter, translate it
        outputR.set('asset', letterNode,'translate',[options.letterSpacing(ii-1,:)]);
    end
    %}
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
        'translate', options.letterPosition(ii,:));


    % THINGS BREAK HERE. We have a 6m distance to the character asset
    % in its recipe, but the recipe we are merging with has from closer to
    % 0, so we get a much shorter distance.
    outputR = piRecipeMerge(outputR, ourLetterAsset.thisR, 'node name', ourLetterAsset.mergeNode);
    
end

