%% Write out the letters as loadable assets
%

%% This is where we will save them
assetDir = fullfile(piRootPath,'data','assets');

%% Pull out each of the letters separately and position them.

letters = {'A','B','C'};
for ii=1:numel(letters)
    letter = letters{ii};
    
    sceneName = 'letters at depth';
    thisR = piRecipeDefault('scene name', sceneName);
    % thisR.show;
    
    for ii=7:-1:2
        thisR.set('asset',ii,'delete');
    end
    % thisR.show;
    
    thisR.set('asset','Camera_B','delete');
    % thisR.show;
    if letter == 'A'
        thisR.set('asset', '001_A_O', 'world position', [0 0 1]);
    else
        thisR.set('asset','001_A_O','delete');
    end
    % thisR.show;
    
    if letter == 'B'
        thisR.set('asset', '001_B_O', 'world position', [0 0 1]);
    else
        thisR.set('asset','001_B_O','delete');
    end
    % thisR.show;
    
    if letter == 'C'
        thisR.set('asset', '001_C_O', 'world position', [0 0 1]);
    else
        thisR.set('asset','001_C_O','delete');
    end
    
    % thisR.show;
    
    thisR.set('from',[0 0 0]);
    thisR.set('to',[0 0 1]);
    
    % thisR.show();
    
    %{
     % I checked the letters this way
     %
        l = piLightCreate('distant','type','distant');
        thisR.set('light',l,'add');
        piAssetGeometry(thisR);
        thisR.show('objects')
        thisR.get('asset','001_C_O','material')
        thisR.set('material','White','reflectance',[.5 .5 .5]);
        piWRS(thisR);
    %}
    
    %
    mergeNode = [letter,'_B'];
    fname = ['letter',letter,'.mat'];
    oFile = thisR.save(fullfile(assetDir,fname));
    save(oFile,'mergeNode','-append');
    
end

%% Merge a letter into the Chess set

%{
% This is an example to test that it worked.

chessR = piRecipeDefault('scene name','chess set');
chessR = piMaterialsInsert(chessR);

% Lysse_brikker is light pieces
% Mrke brikker must be dark pieces
% piAssetGeometry(chessR);

theLetter = piAssetLoad('letterA');

piRecipeMerge(chessR,theLetter.thisR,'node name',theLetter.mergeNode);
chessR.show('objects');

to = chessR.get('to');
chessR.set('asset','001_A_O','world position',to + [0 0.1 0]);
chessR.set('asset','001_A_O','material name','glass');
piWRS(chessR,'render type','radiance');

%}


