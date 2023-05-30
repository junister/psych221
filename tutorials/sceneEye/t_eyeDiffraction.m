%% t_eyeDiffraction.m
%
% We recommend you go through t_eyeIntro.m before running
% this tutorial.
%
% This tutorial renders a retinal image of "slanted bar." We can then use
% this slanted bar to estimate the modulation transfer function of the
% optical system.
%
% We also show how the color fringing along the edge of the bar due to
% chromatic aberration. 
%
% Depends on: ISETBIO, Docker, ISETCam
%
%  
% See also
%   t_eyeArizona, t_eyeNavarro
%

%% Check ISETBIO and initialize

if piCamBio
    fprintf('%s: requires ISETBio, not ISETCam\n',mfilename); 
    return;
end
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the slanted bar scene

thisSE = sceneEye('slantedEdge','eye model','arizona');
thisSE.set('to',[0 0 0]);

thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);

% Set up the image
thisSE.set('fov',2);                % Field of view
thisSE.set('spatial samples',256);  % Number of OI sample points
thisSE.set('rays per pixel',256);
thisSE.set('focal distance',thisSE.get('object distance','m'));
thisSE.set('lens density',0);       % Remove pigment. Yellow irradiance is harder to see.

%% Scene

thisDockerGPU = dockerWrapper;
thisSE.set('use pinhole',true);
thisSE.piWRS('docker wrapper',thisDockerGPU,'name','pinhole');  % Render and show

%% Render with model eye, varying diffraction setting

% Use model eye
thisSE.set('use optics',true);

% This sets the chromaticAberrationEnabled flag and the integrator to
% spectral path.
% Now works in V4 - May 28, 2023 (ZL)
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);

% With diffraction and big pupil
thisSE.set('diffraction',true);
thisSE.set('pupil diameter',4);
thisSE.summary;

humanDocker = dockerWrapper.humanEyeDocker;
oi = thisSE.piWRS('name','arizona-4mm-diffraction','docker wrapper',humanDocker);

%%
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('4 mm diffraction')

%% Diffraction should not matter

% Turn off diffraction.  With big pupil it shouldn't matter
thisSE.set('diffraction',false);
thisSE.summary;

oi = thisSE.piWRS('name','arizona-4mm-nodiffraction','docker wrapper',humanDocker);

oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('4 mm no diffraction');

%% Diffraction with a small pupil should matter

thisSE.set('rays per pixel',1024);
thisSE.set('pupil diameter',1);
thisSE.set('diffraction',false);
thisSE.summary;

oi = thisSE.piWRS('name','1mm-nodiffraction','docker wrapper',humanDocker);

%%
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('1 mm no diffraction');

%% Diffraction should matter.

% Make a direct comparison
thisSE.set('diffraction',true);
thisSE.summary;

oi = thisSE.piWRS('name','1mm-diffraction','docker wrapper',humanDocker);

oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('1 mm no diffraction');

%%  Maybe we should be smoothing the curve at the edge?

thisSE.set('rays per pixel',4096);
thisSE.set('pupil diameter',0.5);
thisSE.set('diffraction',true);
thisSE.summary;

oi = thisSE.piWRS('name','0.5mm-diffraction','docker wrapper',humanDocker);

%%
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('Half mm pupil diffraction on')

%%  Maybe we should be smoothing the curve at the edge?

thisSE.set('diffraction',false);
thisSE.summary;

oi = thisSE.piWRS('name','0.5mm-nodiffraction','docker wrapper',humanDocker);

%%
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title('Half mm off')
%% END