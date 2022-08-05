%% v_recipeValidation
%
% Try most of the recipes in data/scenes.  Some need a little help to
% render.  Say a skymap or some materials.

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','CornellBoxReference');
thisR.set('skymap','room.exr');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','cornell_box');
thisR.set('skymap','room.exr');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','lettersAtDepth');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','materialball_cloth');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','materialball');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','car');
thisR.set('skymap','room.exr');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','bunny');
thisR.set('nbounces',5);
thisR.set('skymap','room.exr');
thisR.set('asset','Bunny_O','scale',3);
piMaterialsInsert(thisR,'names','glossy-red');
thisR.set('asset','Bunny_O','material name','glossy-red');
piWRS(thisR);

%%
fname = fullfile(piRootPath,'data','scenes','teapot-set','TeaTime-converted.pbrt');
if isfile(fname)
    thisR = piRead(fname,'exporter','PARSE');
    piWRS(thisR);
end
%% END

