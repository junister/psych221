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

