%% Illustrate how to read a PBRT file and render
%
% Brief description
%
%   Read and render the ChessSet scene. 
% 
% Dependencies
%
%    ISET3d, ISETCam or ISETBio, JSONio
%
%  Check that you have the updated docker image by running
%
%    docker pull vistalab/pbrt-v4-cpu (or version for gpu)
%
% See also
%   thisR.list produces a list of the files on your system.


%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read a file for the Remote Data site

% This is the INPUT file name
% thisR = piRecipeDefault('scene name','cornellbox');
% thisR = piRecipeDefault('scene name','coloredCube');
% thisR = piRecipeDefault('scene name','kitchen');
% thisR = piRecipeDefault('scene name','contemporary-bathroom');
thisR = piRecipeDefault('scene name','ChessSet');

%% Change render quality
thisR.set('film resolution',[192 192]);
thisR.set('rays per pixel',96);
thisR.set('n bounces',1); % Number of bounces
thisR.set('film rendertype',{'radiance','depth'});
%% Render
tic
piWrite(thisR);
toc
%%  Create the scene
[scene, result] = piRender(thisR);

%%  Show it and the depth map
sceneWindow(scene);

%%
scenePlot(scene,'depth map');

%%