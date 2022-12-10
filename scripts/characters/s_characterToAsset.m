%% Proto script for turning pbrt characters into
%  assets that we can merge

    recipeDir = piDirGet('character-recipes');
    charAssetDir = piDirGet('character-assets');

for ii = 0:9 %number assets
    characterRecipe = [num2str(ii) '-pbrt.pbrt'];
    thisR = piRead(characterRecipe);
    n = thisR.get('asset names');

    % Save in assets/characters instead...
    saveFile = [erase(characterRecipe,'.pbrt') '.mat'];
    oFile = thisR.save(fullfile(charAssetDir,saveFile));

    letter = num2str(ii); % hard-code for testing
    mergeNode = [letter,'_B'];
    save(oFile,'mergeNode','-append');
end

% Generate letters
Alphabet_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Alphabet_LC = lower(Alphabet_UC);

allLetters = [Alphabet_LC Alphabet_UC];

for ii = 1:numel(allLetters)
    characterRecipe = [allLetters(ii) '-pbrt.pbrt'];
    thisR = piRead(characterRecipe);
    n = thisR.get('asset names');

    % Save in assets/characters instead...
    saveFileStub = erase(characterRecipe,'.pbrt');
    if isequal(upper(allLetters(ii)),allLetters(ii))
        saveFile = [saveFileStub '-UC.mat'];
    else
        saveFile = [saveFileStub '.mat'];
    end
    oFile = thisR.save(fullfile(charAssetDir,saveFile));

    letter = allLetters(ii); % hard-code for testing
    mergeNode = [letter,'_B'];
    save(oFile,'mergeNode','-append');
end

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
chessR.set('asset', '001_001_1_O', 'world position', [0 0 1]);
%chessR.set('asset','001_001_1_O','world position',to + [0 0.1 -0.65]);
chessR.set('asset','001_001_1_O','scale',[.3 .3 .3]);
%chessR.set('asset','001_001_1_O','rotate',[-90 45 0]);
chessR.set('asset','001_001_1_O','material name','brickwall001');
piWRS(chessR,'render type','radiance');

%}

