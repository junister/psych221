% Quick example of remote rendering one of the scenes
% from Matt Pharr's repo:
%
% DJC

%%
thisR = piRecipeDefault("scene name",'bmw-m6');

% You can adjust the render parameters, such as
% thisR.set('rays per pixel',1024)

%% Render
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);

%% You can also execute this the usual way as
% piWRS(thisR,'remotescene',true);

