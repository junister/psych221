% Quick example of remote rendering one of the scenes
% from Matt Pharr's repo:

% One of the simplest pbrt-v4-scenes
thisR = piRecipeDefault("scene name",'bmw-m6');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

% Something more complex
thisR = piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);