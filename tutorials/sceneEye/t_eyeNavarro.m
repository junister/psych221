%% t_eyeNavarro.m
%
% We recommend you go through t_eyeIntro.m before running
% this tutorial.
%
% This tutorial renders the PBRT SCENE "letters at depth" using the Navarro
% eye model.  The script illustrates how to
%
%   * set up a sceneEye with the Navarro model
%   * position the camera to center on a specific scene object
%   * render with chromatic aberration (slow)
%
% Depends on: 
%    ISETBio, ISET3d, Docker
%
% Wandell, 2020
%
% See also
%   t_eyeArizona, t_eyeLeGrand
%

%% Check ISETBIO and initialize

if piCamBio
    fprintf('%s: requires ISETBio, not ISETCam\n',mfilename); 
    return;
end
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Here are the World positions of the letters in the scene

% The units are in meters
toA = [-0.0486     0.0100     0.5556];
toB = [  0         0.0100     0.8333];
toC = [ 0.1458     0.0100     1.6667];

%% Show the scene

% This is rendered using a pinhole so the rendering is fast.  It has
% infinite depth of field (no focal distance).
thisSE = sceneEye('letters at depth');

thisSE.set('render type',{'radiance','depth'});

% Position the eye off to the side so we can see the 3D easily
from = [0.25,0.3,-0.2];
thisSE.set('from',from);

% Look at the position with the 'B'.  The values for each of the letters
% are included above.
thisSE.set('to',toB);

% Have a quick check with the pinhole
thisSE.set('use pinhole',true);

% Given the distance from the scene, this FOV captures everything we want
thisSE.set('fov',25);             % Degrees

% Render the scene
thisSE.recipe.set('render type', {'radiance','depth'});

%% Render as a scene with the GPU docker wrapper

thisDocker = dockerWrapper;
scene = thisSE.piWRS('docker wrapper',thisDocker);

% scene = thisSE.render('docker wrapper',thisDWrapper);
% sceneWindow(scene);   

thisSE.summary;

% You can see the depth map if you like
%   scenePlot(scene,'depth map');

%% Now use the optics model with chromatic aberration

% Turn off the pinhole.  The model eye (by default) is the Navarro model.
thisSE.set('use optics',true);

% True by default anyway
thisSE.set('mmUnits', false);

% We turn on chromatic aberration.  That slows down the calculation, but
% makes it more accurate and interesting.  We often use only 8 spectral
% bands for speed and to get a rought sense. You can use up to 31.  It is
% slow, but that's what we do here because we are only rendering once. When
% the GPU work is completed, this will be fast!

%{
% Needs to work with spectral path integrator.
% Zhenyi will make that work in V4.
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);
%}

% Distance in meters to objects to govern accommodation.
thisSE.set('to',toA); distA = thisSE.get('object distance');
thisSE.set('to',toB); distB = thisSE.get('object distance');
thisSE.set('to',toC); distC = thisSE.get('object distance');
thisSE.set('to',toB);

% This is the distance we set our accommodation to that. Try distC + 0.5
% and then distA.  At a resolution of 512, I can see the difference.  I
% don't really understand the units here, though.  (BW).
%
% thisSE.set('accommodation',1/(distC + 0.5));  

thisSE.set('object distance',distC);  

% We can reduce the rendering noise by using more rays. This takes a while.
thisSE.set('rays per pixel',512);      

% Increase the spatial resolution by adding more spatial samples.
thisSE.set('spatial samples',512);     

% Ray bounces
thisSE.set('n bounces',3);

%% This takes longer than the pinhole rendering

% Runs on the CPU on mux for humaneye case.  Make it explicit in this case.
thisDocker = dockerWrapper.humanEyeDocker;
thisSE.piWRS('docker wrapper',thisDocker);

% Summarize
thisSE.summary;

%% Set accommodation to a different distance.

thisSE.set('accommodation',1/distC);  

% Default is humanEyeDocker, so try just the default.  Should also work.
thisSE.piWRS;

thisSE.summary;

%% END
