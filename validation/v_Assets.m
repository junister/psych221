% Test case for merging assets into recipes
ieInit;

parentRecipe = piRecipeDefault('scene name','cornell_box');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant',...
    'cameracoordinate', true);
recipeSet(parentRecipe,'lights', ourLight,'add');
piWRS(parentRecipe);

assetFiles = dir([fullfile(piRootPath,'data','assets'),filesep(),'*.mat']);
report = '';
for ii = 1:numel(assetFiles)

    % I think we need to reload to avoid issues
    % from previous runs
    parentRecipe = piRecipeDefault('scene name','cornell_box');
    lightName = 'from camera';
    ourLight = piLightCreate(lightName,...
        'type','distant',...
        'cameracoordinate', true);
    recipeSet(parentRecipe,'lights', ourLight,'add');
    assetName = assetFiles(ii).name;
    try
        ourAsset = piAssetLoad(assetName);
        combinedR = piRecipeMerge(parentRecipe, ourAsset.thisR);
        piWRS(combinedR);
        report = [report sprintf("Asset: %s Succeeded.\n", assetName)]; %#ok<AGROW>
    catch
        % dockerWrapper.reset;
        report = [report sprintf("Asset: %s failed \n", assetName)]; %#ok<AGROW>
    end

end
fprintf("Asset Validation Results: \n");
fprintf("%s", report);

