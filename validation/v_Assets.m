% v_Assets
%
% Validate merging assets into recipes
%
% This checks that we can merge the pre-computed assets into a simple
% scene, in this case the Cornell Box
%
% DJC and others
%
% See also
%   piAssetLoad, piRecipeMerge, piDirGet

%% Initialize ISETCam and ISET3d-V4
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render each asset using the Cornell box scene as the base scene
%  

parentRecipe = piRecipeDefault('scene name','cornell_box');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant',...
    'cameracoordinate', true);
recipeSet(parentRecipe,'lights', ourLight,'add');
piWRS(parentRecipe);

%% The pre-computed assets

assetFiles = dir([fullfile(piDirGet('assets'),filesep(),'*.mat')]);
fprintf('Found %d assets\n',numel(assetFiles));

%% Loop over each asset

% Return a report
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
    fprintf('\n\nTesting: %s\n_________\n',assetName);
    
    try
        % Load the asset
        ourAsset  = piAssetLoad(assetName);
        
        % Scale its size to be good for the Cornell Box
        thisID = ourAsset.thisR.get('objects');   % Object id
        sz = ourAsset.thisR.get('asset',thisID(1),'size');
        ourAsset.thisR.set('asset',thisID(1),'scale',[0.1 0.1 0.1] ./ sz);
        
        % Merge it with the Cornell Box
        combinedR = piRecipeMerge(parentRecipe, ourAsset.thisR, 'node name',ourAsset.mergeNode);
        % piAssetGeometry(combinedR);
        
        % Render it
        piWRS(combinedR);
        report = [report sprintf("Asset: %s Succeeded.\n", assetName)]; %#ok<AGROW>
    catch
        % If it failed, we report that.
        % dockerWrapper.reset;
        report = [report sprintf("Asset: %s failed \n", assetName)]; %#ok<AGROW>
    end

end
fprintf("Asset Validation Results: \n");
fprintf("%s", report);

%%