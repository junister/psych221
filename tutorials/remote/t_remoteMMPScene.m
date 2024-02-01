% Quick example of remote rendering one of the scenes
% from Matt Pharr's repo:

thisR = piRecipeDefault("scene name",'bmw-m6');
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);
