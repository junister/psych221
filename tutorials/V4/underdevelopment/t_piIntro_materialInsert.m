
ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name', 'MacBethChecker');

% piWRS(thisR);
thisR = piMaterialsInsert(thisR);
object = thisR.get('asset', '001_colorChecker_O');

objNames = thisR.get('object names');
matNames = thisR.get('material', 'names');
newMatNames = matNames(~piContains(matNames, 'Patch'));

for ii = 2:numel(newMatNames) + 1
    thisR.set('asset', objNames{ii}, 'materialname', newMatNames{ii-1});
end
% thisR.set('asset', '008_colorChecker_O', 'materialname', 'mahogany');

piWRS(thisR);