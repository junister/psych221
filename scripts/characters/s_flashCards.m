% Might become a way to render specific characters on a background
% in preparation to reconstruction and scoring
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Something still isn't quite right about the H and I assets
Alphabet_UC = 'ABCDEFGJKLMNOPQRSTUVWXYZ';
Alphabet_LC = 'abcdefghijklmnopqrstuvwxyz';

humanEye = ~piCamBio(); % if using ISETBio, then use human eye

% Start with a "generic" recipe
thisR = piRecipeCreate('lettersatdepth');

backWall = piAssetSearch(thisR,'object name','Wall');
recipeSet(thisR, 'up', [0 1 0]);
recipeSet(thisR, 'from', [0 0 0]);
recipeSet(thisR, 'to', [0 0 5]);

addMaterials(thisR)
wallMaterial = 'wood-light-large-grain';
piAssetSet(thisR, backWall, 'material name', wallMaterial);

% I think at this point Wall is at z=2 and a,b,c are between camera & wall
piWRS(thisR);
thisR.birdsEye();


function addMaterials(thisR)
% should inherit from parent


% See list of materials, if we want to select some
allMaterials = piMaterialPresets('list');

% Loop through our material list, adding whichever ones work
for iii = 1:numel(allMaterials)
    try
            piMaterialsInsert(thisR, 'names',allMaterials{iii});
    catch
        warning('Material: %s insert failed. \n',allMaterials{ii});
    end
end
end

