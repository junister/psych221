%% Show how to extract various "factoids" about the scene
%
% Description:
%   This renders the teapot scene in the data directory of the
%   ISET3d repository. It then shows how to use iset3d to get various
%   "factoid" images about scene properties in the image plane.
%
%   By a factoid image, we mean an image that provides information about
%   some aspect of the underlying scene at each pixel in the radiance
%   image. The ability to extract factoids provides us with the ability to
%   label images, for example for applications in machine learning.
%
%   depth - Depth map of the scene at each pixel.
%     Q. IS THE DEPTH MAP DISTANCE ALONG CAMERAL LINE OF SIGHT?
%
%   illumination - Illumination at each pixel.  Obtained by rendering with
%     all materials set to white matte.
%     Q. WHY DOES THE ILLUMINATION IMAGE HAVE WHAT LOOKS LIKE A COLORED
%     SCENE IN THE BACKGROUND (OUTSIDE)?
%
%   material - Indicator variable for material at each pixel.
%     Q. THERE ARE ONLY TWO MATERIALS IN THIS MAP.  IS THAT BECAUSE THE
%     SAME MATERIAL TYPE GETS THE SAME INDICATOR, EVEN IF PARAMETERS ARE
%     DIFFERENT? IF SO, IS THERE A WAY TO GET AN INDICATOR VARIABLE WITH
%     THE LATTER?
%     Q. HOW DO I CONNECT THE INDICATOR WITH THE UNDERLYING DATA STRUCTURE?
%
%   mesh - Indicator variable for the mesh at each pixel.
%      Q. THIS LOOKS LIKE WHAT I EXPECTED FOR THE MATERIAL MAP.  WHAT IS A 
%      MESH?
%      Q. HOW DO I CONNECT THE INDICATOR WITH THE UNDERLYING DATA STRUCTURE?

%   image coordinates - 3d scene coordinates at each pixel.
%      Q. THESE ARE NOT AS I EXPECTED THEM TO LOOK.  FOR EXAMPLE, I
%      EXPECTED THE IMAGE OF THE X COORDINATE TO BE MORE OR LESS A LEFT TO
%      RIGHT GRADIENT IN THE IMAGE.  CAN SOMEONE UNPACK WHY THESE LOOK THE
%      WAY THEY DO?
%
%   surface normals - 
%      Q. IS THERE A WAY TO GET SURFACE NORMALS?
% 
% Dependencies:
%    ISET3d, (ISETCam or ISETBio), JSONio
%
% See also
%   t_piIntro_*

%% History:
%   12/27/20 dhb  Started on this, although mostly just produced questions
%                 about things I don't understand.

%% Initialize ISET and Docker
%
% We start up ISET and check that the user is configured for docker
clear; close all; ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the scene recipe file
%
% Need a scene that has a material library
sceneName = 'SimpleScene';
thisR = piRecipeDefault('scene name','SimpleScene');

%% Set render quality
%
% This is a low resolution for speed.
thisR.set('film resolution',[200 150]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',1); 

%% The output will be written here
outFile = fullfile(piRootPath,'local',sceneName,'scene.pbrt');
thisR.set('outputFile',outFile);

%% Set up the render quality
%
% There are many different parameters that can be set.
thisR.set('film resolution',[192 192]);
thisR.set('pixel samples',128);
thisR.set('max depth',1); % Number of bounces

%% Write out recipe
piWrite(thisR);

%% Render radiance image and show.
[theScene] = piRender(thisR,'renderType','radiance');
sceneWindow(theScene);
theScene = sceneSet(theScene,'gamma',0.7);

%% Render depth map and show.
%
% When obtained this way, depthMap is an image that we add to the scene.
% give depth to each pixel.
[depthMap] = piRender(thisR,'renderType','depth');
theScene = sceneSet(theScene,'depth map',depthMap);
scenePlot(theScene,'depth map');

%% Render illumination image and show. Broken.
[sceneIllumination] = piRender(thisR,'renderType','illuminant only');
theScene = sceneSet(theScene,'illuminant photons',sceneIllumination);
scenePlot(theScene,'illuminant image');

%% Material.
%
% This is an image with a material indicator variable at each pixel.
% This only has two discrete values in it, which doesn't make sense to me.
[materialMap] = piRender(thisR,'renderType','material');
figure; imshow(materialMap/max(materialMap(:)));

%% Mesh
%
% This should have a label for the mesh at each pixel.  It looks like
% expect for the material map.  I don't think I know what a mesh is.
[meshMap] = piRender(thisR,'renderType','mesh');
figure; imshow(meshMap/max(meshMap(:)));

%% Image coordinates
%
% I don't why these images look the way they do.
[coords] = piRender(thisR, 'render type','coordinates');
figure; imagesc(coords(:,:,1)); title('X coordinates');
figure; imagesc(coords(:,:,2)); title('Y coordinates');
figure; imagesc(coords(:,:,3)); title('Z coordinates');
