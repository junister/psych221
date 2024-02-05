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

%% Something more complex
thisR = piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

%% Move the camera
origFrom = thisR.get('from');
thisR.set('from',[8 3.9 -30]);
piWRS(thisR,'remote scene',true);

% Something more complex
thisR = piRecipeDefault('scene name','landscape');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Something more complex
thisR = piRead('book.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

%% Not finding relative paths

% Something more complex
thisR = piRecipeDefault('scene name','sanmiguel');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

