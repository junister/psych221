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
fname = fullfile(piRootPath,'data','V4','web','contemporary-bathroom','contemporary-bathroom.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[300 300]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',3);
piWRS(thisR);

fname = fullfile(piRootPath,'data','V4','web','barcelona-pavilion','pavilion-day.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[300 300]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',3);
[scene, result] = piWRS(thisR);

fname = fullfile(piRootPath,'data','V4','web','kitchen','kitchen.pbrt');
exist(fname,'file')
thisR = piRead(fname,'exporter','Copy');
thisR.set('film resolution',[384 384]);
thisR.set('rays per pixel',256);
thisR.set('n bounces',6);
piWRS(thisR);

%{
*** Rendering time for this job (pavilion-day) was 3.3 sec ***

Warning: Docker did not run correctly 
> In piRender (line 290)
In piWRS (line 81) 
Status:
     1

Result:
pbrt version 4 (built May  8 2022 at 00:54:47)

Copyright (c)1998-2021 Matt Pharr, Wenzel Jakob, and Greg Humphreys.

The source code to pbrt (but *not* the book contents) is covered by the Apache 2.0 License.

See the file LICENSE.txt for the conditions of the license.

[1m[31mError[0m: pavilion-day_materials.pbrt:2:59: "value": unused parameter.


Error using piWRS (line 84)
Render failed.
%}

% We need the V4 scenes now.  I think cardinal.stanford.edu has V3
% scenes.  This one fails because of the 'tga' files and perhaps other
% reasons.  When we ran piPBRTUpdateV4 it put warnings into the PBRT
% file!

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
