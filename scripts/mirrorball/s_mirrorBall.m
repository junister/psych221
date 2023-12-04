%% s_illuminationMirrorBall
%
% Move script around and create other examples.  This is just a scratch
% beginning.  Change names.
%
% Puts a mirror ball (sphere) into the scene.  Testing the lighting.

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the parameters

resolution = [320 320]*2;

thisR = piRecipeDefault('scene name','kitchen');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

% Load the sphere and change its size to fit.  It comes in as 1 meter
% diameter.
tmp = piAssetLoad('sphere');
sphereR = tmp.thisR;
mergedR = piRecipeMerge(thisR,sphereR);
mergedR.set('asset','Sphere_O','scale',0.15);

piMaterialsInsert(mergedR,'names',{'mirror'});
mergedR.set('asset','Sphere_O','material name','mirror');

%% Choose a position

% The 'to' is in the middle of the air.  This seems to be the 0,0,0
% position.  The object positions seem to be defined by the values in their
% meshes rather than be branch nodes.
mergedR.set('to distance',1.5);
to = mergedR.get('to');
mergedR.set('asset','Sphere_O','world position',to);


%% The positions in kitchen seem to be based on the mean values of the mesh
% that is a guess for me now.
%{
kettlePos = mergedR.get('asset','Mesh241_O','world position');
thisR.set('to',kettlePos);
mergedR.set('asset','Sphere_O','world position',pos);
%}

%%
scene = piWRS(mergedR);

%%