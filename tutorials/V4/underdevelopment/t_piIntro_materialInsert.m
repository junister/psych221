%% Insert materials into a recipe
%
% We use piMaterialsInsert to select some materials that we add to a
% recipe.  In the future this will look like
%
%    thisR = piMaterialsInsert(thisR,{'materialClass1','materialClass2', ...});
%
% For now we just insert all 14 of the materials we are experimenting with.
%
% ZLy and BW
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Show them on the MCC

thisR = piRecipeDefault('scene name', 'MacBethChecker');

% Add a light so we can see through the glass
fileName = 'cathedral_interior.exr';
envLight = piLightCreate('background', ...
    'type', 'infinite',...
    'mapname', fileName);
thisR.set('lights', 'add', envLight);                       
thisR.set('lights','background','rotation val',{[0 0 5 0], [45 1 0 0]});

% piWRS(thisR);
thisR = piMaterialsInsert(thisR);
% object = thisR.get('asset', '001_colorChecker_O');

objNames = thisR.get('object names');
matNames = thisR.get('material', 'names');

% Patch are the current materials.  We don't want to use them again
% Glass is not looking clear.  Adjust its parameters!
newMatNames = matNames(~piContains(matNames, 'Patch'));
for ii = 2:numel(newMatNames) + 1
    thisR.set('asset', objNames{ii}, 'materialname', newMatNames{ii-1});
end

piWRS(thisR);

%%
% thisR.set('asset', '008_colorChecker_O', 'materialname', 'mahogany');


%%