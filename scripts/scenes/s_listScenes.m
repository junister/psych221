% s_listScenes

%%
ourDB = idb();
isetScenes = ourDB.connection.find('ISETScenesPBRT');
autoScenes = ourDB.connection.find('autoScenesPBRT');
isetScenes(:).sceneID
autoScenes(:).sceneID

isetScenes(:).fileName

%%
%%
thisR = piRecipeDefault("scene name",'bmw-m6');
thisR = piRecipeDefault("scene name",'bmw-m6');

% You can adjust the render parameters, such as
% thisR.set('rays per pixel',1024)

%% Render
piWrite(thisR);
scene = piRender(thisR,'remotescene',true);
sceneWindow(scene);