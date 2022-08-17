%% s_bmwm6
%
% This one PARSED up without any editing from us, I think.
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','bmw-m6');
scene = piWRS(thisR);
ieReplaceObject(piAIdenoise(scene));
[idMap, oList] = piLabel(thisR);

ieNewGraphWin;image(idMap);  colormap("prism"); axis image;

%% END