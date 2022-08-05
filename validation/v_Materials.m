% Need to add a validation script that runs through all materials!

% Starting code from the MaterialInsert test:
thisR = piRecipeDefault('scene name','bunny');

thisR.set('skymap','room.exr');
thisR.set('asset','001_Bunny_O','scale',4);
thisR.set('nbounces',3);

%%
piMaterialsInsert(thisR,'names','glossy-red');

thisR.set('asset','001_Bunny_O','material name','glossy-red');
piWRS(thisR);

