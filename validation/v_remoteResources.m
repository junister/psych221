% Validate whether we can render our scenes using remote resources

% bunny has no light sources, need more code
%thisR = piRecipeDefault('scene name', 'bunny');
%piWRS(thisR, 'useremoteresources', true);

thisR = piRead('arealight.pbrt');
piWRS(thisR, 'useRemoteResources', true);

% needs a light source?
%thisR = piRead('car.pbrt');
%piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'checkerboard');
piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'ChessSet');
piWRS(thisR, 'useRemoteResources', true);

% needs light source
%thisR = piRecipeDefault('scene name', 'coordinate');
%piWRS(thisR, 'useRemoteResources', true);

% needs light source
%thisR = piRecipeDefault('scene name', 'cornell_box');
%piWRS(thisR, 'useRemoteResources', true);

% Note: This looks pretty black, probably because it needs a light?
thisR = piRecipeDefault('scene name', 'CornellBoxReference');
piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'lettersAtDepth');
piWRS(thisR, 'useRemoteResources', true);

% Needs a light source
%thisR = piRecipeDefault('scene name', 'MacBethChecker');
%piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'materialball');
piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'materialball_cloth');
piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'SimpleScene');
piWRS(thisR, 'useRemoteResources', true);

% No light source
%thisR = piRecipeDefault('scene name', 'slantedEdge');
%piWRS(thisR, 'useRemoteResources', true);

% No light source
%thisR = piRecipeDefault('scene name', 'sphere');
%piWRS(thisR, 'useRemoteResources', true);

thisR = piRecipeDefault('scene name', 'stepfunction');
piWRS(thisR, 'useRemoteResources', true);

%% Teapot Fails!
try
    thisR = piRecipeDefault('scene name', 'teapot');
    piWRS(thisR, 'useRemoteResources', true);
catch err
    fprintf("Teapot Failed with error %s!!! \n", err.message);
end

% TBD has an issue on Windows with fbx to pbrt
%thisR = piRecipeDefault('scene name', 'testplane');
%piWRS(thisR, 'useRemoteResources', false);


