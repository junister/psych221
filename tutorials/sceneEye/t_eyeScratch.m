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

thisSE = sceneEye('slantedEdge','eye model','navarro');
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
thisSE.set('pupil diameter',3);

fprintf('Object distance %.2f\n',thisSE.get('object distance','m'));

humanDocker = dockerWrapper.humanEyeDocker;
for ii=[0.06 0.08 0.1 0.3 0.5 0.7 1]
    thisSE.set('focal distance',ii);
    thisSE.summary;
    name = sprintf('distance %.3f',thisSE.get('focal distance','m'));
    oi = thisSE.piWRS('name',name,'docker wrapper',humanDocker,'show',false);
    oi = piAIdenoise(oi);
    oiWindow(oi);
end

%% END