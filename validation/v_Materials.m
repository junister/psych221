% A validation script that runs through the preset materials
%
% We change the material on the bunny set against a bright background.
% This lets us judge transparency.
%
% See also
%  

%% Starting code from the MaterialInsert test:
ieInit;

thisR = piRecipeDefault('scene name','bunny');
bunnyID = piAssetSearch(thisR,'object name','Bunny');

thisR.set('skymap','room.exr');
thisR.set('asset',bunnyID,'scale',4);
thisR.set('nbounces',3);

%% Some debate about material 
results = [];
allMaterials = piMaterialPresets('list');

for ii = 1:numel(allMaterials)
    try
        % we need to re-load so a broken material
        % doesn't cause us to error out
        thisR = piRecipeDefault('scene name','bunny');
        thisR.set('skymap','room.exr');
        thisR.set('asset',bunnyID,'scale',4);
        thisR.set('nbounces',3);
        piMaterialsInsert(thisR,'names',allMaterials{ii});
        thisR.set('asset',bunnyID,'material name',allMaterials{ii});
        piWRS(thisR,'render flag','hdr');
        results = cat(1,results,sprintf("Material: %s Succeeded\n",allMaterials{ii}));
    catch EX
        results = cat(1,results, sprintf("Material: %s FAILED: %s\n",allMaterials{ii},EX.message));
    end
end

%% Print out the results

for ii = 1:numel(results)   
    fprintf(results{ii});
end

%% END

