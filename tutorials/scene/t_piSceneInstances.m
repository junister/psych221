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

%% 
thisR = piRecipeDefault('chess set');

