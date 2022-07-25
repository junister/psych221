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

yellowM = '001_figure_6m_O';
yellowPos = thisR.get('asset',yellowM,'world position');
yellowB = '0022ID_figure_6m_B';
thisR = piObjectInstanceCreate(thisR,yellowB,'position',yellowPos + [0.5 0.5 0.5]);
