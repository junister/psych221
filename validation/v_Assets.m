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
%{
Asset Validation Results: 
Asset: EIA.mat Succeeded.
Asset: bunny.mat Succeeded.
Asset: coordinate.mat Succeeded.
Asset: face.mat Succeeded.
Asset: glasses.mat failed % Zheng special case.
Asset: gridlines.mat Succeeded.
Asset: letterA.mat Succeeded.
Asset: letterB.mat Succeeded.
Asset: letterC.mat Succeeded.
Asset: macbeth.mat Succeeded.
Asset: mccCB.mat failed   % Zheng special case.
Asset: plane.mat failed   % Not sure what this is yet.
Asset: pointarray512.mat Succeeded.
Asset: ringsrays.mat Succeeded.
Asset: slantedbar.mat Succeeded.
Asset: sphere.mat Succeeded.
%}

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
        thisName = ourAsset.thisR.get('object names no id');
        sz = ourAsset.thisR.get('asset',thisName{1},'size');
        ourAsset.thisR.set('asset',thisName{1},'scale',[0.1 0.1 0.1] ./ sz);
        
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