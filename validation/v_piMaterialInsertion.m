%% Testing material insertion
%

%% Red
thisR = piRecipeDefault('scene name','bunny');

thisR.set('skymap','room.exr');
thisR.set('asset','001_Bunny_O','scale',4);
thisR.set('nbounces',3);

%%
piMaterialsInsert(thisR,'names','glossy-red');

thisR.set('asset','001_Bunny_O','material name','glossy-red');
piWRS(thisR);

%% 
piMaterialsInsert(thisR,'names','glossy-black');
thisR.set('asset','001_Bunny_O','material name','glossy-black');
piWRS(thisR);

%% Now a few at at time
thisR = piRecipeDefault('scene name','bunny');

thisR.set('skymap','room.exr');
thisR.set('asset','001_Bunny_O','scale',4);
thisR.set('nbounces',5);

%% Mirror 
piMaterialsInsert(thisR,'names',{'mirror','glass'});
thisR.set('asset','001_Bunny_O','material name','mirror');
piWRS(thisR);

%% Glass
thisR.set('asset','001_Bunny_O','material name','glass');
piWRS(thisR);

%% End
