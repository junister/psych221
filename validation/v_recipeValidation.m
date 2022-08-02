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
thisR.set('asset','001_Bunny_O','scale',3);
piMaterialsInsert(thisR,'glossy-red');
thisR.set('asset','001_Bunny_O','material name','glossy-red');
piWRS(thisR);

%%
fname = fullfile(piRootPath,'data','scenes','teapot-set','TeaTime-converted.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','PARSE');
piWRS(thisR);

%% END

%{
% We need the V4 scenes now.  I think cardinal.stanford.edu has V3
% scenes.

s = ieWebGet('resource type','pbrtv4','resource name','bmw-m6');
fname = fullfile(piRootPath,'data','scenes','web','bmw-m6','bmw-m6.pbrt');
exist(fname,'file')

thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[384 384]);
thisR.set('rays per pixel',256);
thisR.set('n bounces',5);
piWRS(thisR);


% This worked at school.  Figure out what we did to fix it (BW).
% The one I put up at cardinal.stanford.edu is not the fixed one.
%
s = ieWebGet('resource type','pbrtv4','resource name','kitchen');
fname = fullfile(piRootPath,'data','scenes','web','kitchen','scene.pbrt');
exist(fname,'file')

thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[384 384]);
thisR.set('rays per pixel',1024);
thisR.set('n bounces',9);
piWRS(thisR);


fname = fullfile(piRootPath,'data','scenes','web','contemporary-bathroom','contemporary-bathroom.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[300 300]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',3);
piWRS(thisR);

fname = fullfile(piRootPath,'data','V4','web','barcelona-pavilion','pavilion-day.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[512 512]);
thisR.set('rays per pixel',1024);
thisR.set('n bounces',4);
[scene, result] = piWRS(thisR);

fname = fullfile(piRootPath,'data','V4','web','barcelona-pavilion','pavilion-night.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[512 512]);
thisR.set('rays per pixel',1024);
thisR.set('n bounces',4);
[scene, result] = piWRS(thisR);



fname = fullfile(piRootPath,'data','V4','web','bistro','bistro_boulangerie.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[384 384]);
thisR.set('rays per pixel',256);
thisR.set('n bounces',4);
piWRS(thisR);
%}

%{
% We need the V4 scenes now.  I think cardinal.stanford.edu has V3
% scenes.  This one fails because of the 'tga' files and perhaps other
% reasons.  When we ran piPBRTUpdateV4 it put warnings into the PBRT
% file!
%}

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
