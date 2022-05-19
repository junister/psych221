%% v_recipeValidation
%
%

thisR = piRecipeDefault('scene name','CornellBoxReference');
thisR.set('skymap','room.exr');
piWRS(thisR);

thisR = piRecipeDefault('scene name','cornell_box');
thisR.set('skymap','room.exr');
piWRS(thisR);

thisR = piRecipeDefault('scene name','lettersAtDepth');
piWRS(thisR);

thisR = piRecipeDefault('scene name','materialball_cloth');
piWRS(thisR);

thisR = piRecipeDefault('scene name','materialball');
piWRS(thisR);

thisR = piRecipeDefault('scene name','car');
thisR.set('skymap','room.exr');
piWRS(thisR);

thisR = piRecipeDefault('scene name','bunny');
piMaterialsInsert(thisR);
thisR.set('skymap','room.exr');
thisR.set('asset','001_Bunny_O','scale',3);
thisR.set('asset','001_Bunny_O','material name','Red');
thisR.set('nbounces',5);
piWRS(thisR);

fname = fullfile(piRootPath,'data','V4','teapot-set','TeaTime-converted.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','PARSE');
piWRS(thisR);

% We need the V4 scenes now.  I think cardinal.stanford.edu has V3
% scenes.
fname = fullfile(piRootPath,'data','V4','web','kitchen','scene.pbrt');
exist(fname,'file')
thisR = piRead(fname);
piWRS(thisR);

%{
fname = fullfile(piRootPath,'data','V4','teapot','teapot-area-light-v4.pbrt');
exist(fname,'file')

thisR = piRead(fname,'exporter','PARSE');
thisR.set('skymap','room.exr');
piMaterialsInsert(thisR);
thisR.set('asset','001_material1-33133_O','material name','wood001');
thisR.set('asset','002_material2-28907_O','material name','wood002');
piWRS(thisR);
piAssetGeometry(thisR);
%}
