%% s_headLens

thisR = piRecipeDefault('scene name','bistro_cafe');

thisR.set('rays per pixel',256);
thisR.set('film resolution',[320 320]);

%% This renders
scene = piWRS(thisR);

%{

The source code to pbrt (but *not* the book contents) is covered by the Apache 2.0 License.

See the file LICENSE.txt for the conditions of the license.

[1m[31mWarning[0m: Couldn't find supported color space that matches chromaticities: r (0.7347, 0.2653) g (0, 1) b (0.0001, -0.077), w (0.32167906, 0.3376722). Using sRGB.

[1m[31mError[0m: textures/MASTER_Glass_Exterior_Normal.png: normal map image must contain R, G, and B channels

%}

%%

% depthRange = thisR.get('depth range');
% depthRange = [1 1];

% thisR.set('lens file','fisheye.87deg.100.0mm.json');
% lensFiles = lensList;
% lensfile = 'fisheye.87deg.100.0mm.json';
% lensfile  = 'dgauss.22deg.50.0mm.json';    % 30 38 18 10

fprintf('Using lens: %s\n',lensfile);
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('focal distance',5);
thisR.set('film diagonal',33);

oi = piWRS(thisR);
