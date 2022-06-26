%% Validate 'skymap' option for adding a skymap
%
% Try a few sky maps
%

%% 
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','sphere');
thisR.set('skymap', 'room.exr');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','sphere');
thisR.set('skymap', 'cathedral_interior.exr');
piWRS(thisR);

%%
thisR = piRecipeDefault('scene name','sphere');
thisR.set('skymap', 'equiarea-rainbow.exr');
piWRS(thisR);

%% END
