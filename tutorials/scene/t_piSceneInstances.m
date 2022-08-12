%% t_piSceneInstances
%
% Show how to add additional instances of an asset to a scene. 
%
%  piObjectInstanceCreate
%
% Also illustrate
%
%  piObjectInstanceRemove
%
% See also
%
 
%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render the basic scene

thisR = piRecipeDefault('scene name','simple scene');
scene = piWRS(thisR);

%% Create a second instance if the yellow guy

oNames = thisR.get('object names');

yellowID = piAssetSearch(thisR,'object name','figure_6m');
yellowPos = thisR.get('asset',yellowID,'world position');

parentID = thisR.get('asset',yellowID,'parent');

thisR = piObjectInstanceCreate(thisR, parentID, 'position',yellowPos + [0.5 0.5 0.5]);

thisR.show;

s = piRender(thisR); sceneWindow(s);

% [scene, result ] = piWRS(thisR);
