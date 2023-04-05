%% v_recipeValidation
%
% Try most of the recipes in data/scenes.  Some need a little help to
% render.  Say a skymap or some materials.

%%
ieInit;
if ~piDockerExists, piDockerConfig; end
validNames = piRecipeCreate('list');

%% This loop should work.
for ii=1:numel(validNames)
    fprintf('\n-----------\n');
    fprintf('Scene:  %s\n',validNames{ii})
    try
        thisR = piRecipeCreate(validNames{ii});
        piWRS(thisR);
        fprintf('Succeeded on %s -- \n',validNames{ii});
    catch
        fprintf('Failed on %s -- \n',validNames{ii});
    end
end

%% END

