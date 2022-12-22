% Experiment with different backgrounds for characters
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Something still isn't quite right about the H and I assets
Alphabet_UC = 'ABCDEFGJKLMNOPQRSTUVWXYZ';
chartRows = 4;
chartCols = 6;

% Use the patches of the MCC as placeholders
thisR = piRecipeCreate('macbeth checker');

% Put our characters in front, starting at the top left
to = thisR.get('to') - [0.5 -0.28 -0.8];

% This needs to be changed to chart box size
horizontalDelta = 0.2;
verticalDelta = -.21;
letterIndex = 0;

letterSize = [0.12,0.1,0.12];
letterRotation = [0 0 0];
letterMaterial = 'wood-light-large-grain';

letterNames = {};
for ii = 1:chartRows
    for jj = 1:chartCols
        letterIndex = letterIndex + 1;
        letter = Alphabet_UC(letterIndex);
        % Move right based on ii, down based on jj, don't change depth for
        % now
        pos = to + [((jj-1) *horizontalDelta) ((ii-1)*verticalDelta) 0]; %#ok<SAGROW>
        [thisR, addLetters] = charactersRender(thisR, letter,'letterSize',letterSize,'letterRotation',letterRotation,'letterPosition',pos,'letterMaterial',letterMaterial);
        letterNames{end+1} = addLetters;
    end
end

thisR.set('name','Sample Character Backgrounds');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);

%add materials from our library
addMaterials(thisR)

% Now vary the materials that compose the letters
varyLettersR = doMaterials(thisR,'type','letters','letterNames',letterNames);
piWRS(varyLettersR);

% Vary patch materials
varyPatchR = doMaterials(thisR,'type','patch');
piWRS(varyPatchR);



function thisR = doMaterials(thisR, options)

arguments
    thisR;
    options.type = 'patch';
    options.letterNames = [];
end


ourMaterialsMap = thisR.get('materials');
ourMaterials = values(ourMaterialsMap);

% we only have 24 patches to modify
for iii = 1:min(numel(ourMaterials),24)
    try
        if isequal(options.type, 'patch')
            if iii < 9
                ourAsset = piAssetSearch(thisR,'object name',['00' num2str(iii+1) '_colorChecker_O']);
            else
                ourAsset = piAssetSearch(thisR,'object name',['0' num2str(iii+1) '_colorChecker_O']);
            end
        else
            ourAsset = piAssetSearch(thisR,'object name',options.letterNames{iii});
        end

        % patches are all first, so start from the back
        % (or we could just add 25 -- mat + 24)
        thisR.set('asset',ourAsset,'material name',ourMaterials{25+iii}.name);
    catch EX
        warning('Material: %s failed with %s. \n',ourMaterials{25+iii}.name, EX.message);
    end
end
end

function addMaterials(thisR)
% should inherit from parent
letterMaterial = 'wood-light-large-grain';

% See list of materials, if we want to select some
allMaterials = piMaterialPresets('list');

% Loop through our material list, adding whichever ones work
for iii = 1:numel(allMaterials)
    try
        % it doesn't like it if we add a material twice
        if ~isequal(allMaterials{iii}, letterMaterial)
            piMaterialsInsert(thisR, 'names',allMaterials{iii});
        end
    catch
        warning('Material: %s insert failed. \n',allMaterials{ii});
    end
end
end
