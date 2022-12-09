%% Proto script for turning pbrt characters into
%  assets that we can merge

% Initial trial balloon
characterRecipe = '1-pbrt.pbrt';
thisR = piRead(characterRecipe);

%{
% Test to see what it looks like:
        l = piLightCreate('distant','type','distant');
        thisR.set('light',l,'add');
        piAssetGeometry(thisR);
        thisR.show('objects')
        %thisR.get('asset','001_C_O','material')
        %thisR.set('material','White','reflectance',[.5 .5 .5]);
        piWRS(thisR);
%}

n = thisR.get('asset names');

recipeDir = piDirGet('character-recipes');
charAssetDir = piDirGet('character-assets');

% Save in assets/characters instead...
saveFile = [erase(characterRecipe,'.pbrt') '.mat'];

oFile = thisR.save(fullfile(charAssetDir,saveFile));

letter = '1'; % hard-code for testing
mergeNode = [letter,'_B'];
save(oFile,'mergeNode','-append');

% TEST CASE BORROWED FROM LETTER SCRIPT:
%% Merge a letter into the Chess set

%{
% This is an example to test that it worked.

chessR = piRecipeDefault('scene name','chess set');
%chessR = piMaterialsInsert(chessR);
piMaterialsInsert(chessR,'groups','all'); 
chessR.get('print materials');
% Lysse_brikker is light pieces
% Mrke brikker must be dark pieces
% piAssetGeometry(chessR);

theLetter = piAssetLoad(which('1-pbrt.mat'));

piRecipeMerge(chessR,theLetter.thisR,'node name',theLetter.mergeNode);
chessR.show('objects');

to = chessR.get('to');
chessR.set('asset','001_001_1_O','world position',to + [0 0.1 0]);
chessR.set('asset','001_001_1_O','material name','glass');
piWRS(chessR,'render type','radiance');

%}

