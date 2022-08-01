%% Testing material insertion
%

%% Red
thisR = piRecipeDefault('scene name','bunny');
piMaterialsInsert(thisR);

thisR.set('skymap','room.exr');
thisR.set('asset','001_Bunny_O','scale',4);
thisR.set('nbounces',3);

%%
thisR.set('asset','001_Bunny_O','material name','Red');
piWRS(thisR);

%% 
thisR.set('asset','001_Bunny_O','material name','Black_glossy');
piWRS(thisR);

%% Mirror
thisR.set('asset','001_Bunny_O','material name','mirror');
piWRS(thisR);

%% Glass
thisR.set('asset','001_Bunny_O','material name','glass');
piWRS(thisR);

%%
