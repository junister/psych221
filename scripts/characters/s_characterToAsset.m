%% Proto script for turning pbrt characters into
%  assets that we can merge

%  D.Cardinal, Stanford University, December, 2022

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

% Code currently assumes OS can tell UC from LC
% Otherwise instead of relying on Matlab path to get pbrt
% files, we'd need to provide a specific path
for ii = 1:numel(allLetters)
    characterRecipe = [allLetters(ii) '-pbrt.pbrt'];
    thisR = piRead(characterRecipe);

    % piRead changes asset names to lower case
    % This means things break when we merge UC letters into recipes
    
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

