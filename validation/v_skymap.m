%% Validate 'skymap' option for adding a skymap
%
% 2022, D.Cardinal
%
% 
thisR = piRecipeDefault('scene name','sphere');
thisR.set('skymap', 'room.exr');
piWRS(thisR);
% add a rotated version
thisR.set('skymap', 'room.exr','rotation val', [-90 -90 -90]);
% now we should see two overlapped skymaps
piWRS(thisR);

