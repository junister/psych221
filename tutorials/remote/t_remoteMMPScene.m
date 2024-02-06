% Quick example of remote rendering one of the scenes
% from Matt Pharr's repo:
%
% DJC

%% One of the simplest pbrt-v4-scenes
thisR = piRecipeDefault("scene name",'bmw-m6');

% You can adjust the render parameters, such as
% thisR.set('rays per pixel',1024)

% Render
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Works
thisR = piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% piRead doesn't work, complains about uneven_bump.png,
% even though it seems to be there?
thisR = piRecipeDefault('scene name','pbrt-book');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

%% Move the camera
origFrom = thisR.get('from');
thisR.set('from',[8 3.9 -30]);
piWRS(thisR,'remote scene',true);

% Now works
thisR = piRecipeDefault('scene name','landscape');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Needs .nvdb file and we don't have a model for 
% that, so need to decide how to handle
thisR = piRecipeDefault('scene name', 'bunny-cloud');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% piRead fails, even when set to Copy
thisR = piRecipeDefault('scene name', 'bunny-fur');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Crown has a 2-tiered folder structure under
% textures, which piRead() doesn't seem to like
thisR = piRecipeDefault('scene name', 'crown');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% dambreak0 renders, but looks weird -- not sure if it correct
% dambreak1 seems just like dambreak0
thisR = piRecipeDefault('scene name', 'dambreak',...
    'file','dambreak1.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Another scene that requires a .nvdb file...
thisR = piRecipeDefault('scene name', 'disney-cloud');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Something renders, but it doesn't look like an explosion
thisR = piRead('explosion.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Ganesha works
thisR = piRecipeDefault('scene name', 'ganesha');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Won't load even with Copy exporter
thisR = piRecipeDefault('scene name','clouds');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Works if you edit out the Finishes... file references
thisR = piRecipeDefault('scene name','sanmiguel');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Need to handle bsdfs
thisR = piRecipeDefault('scene name','contemporary-bathroom');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

