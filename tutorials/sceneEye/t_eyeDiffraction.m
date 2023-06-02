%% t_eyeDiffraction.m
%
% Using the "slanted edge", we render with different pupil sizes and with
% diffraction turned on and off.
%
% First thing to note - changing the pupil size changes chromatic
% aberration. 
%
% Not sure yet that we can see the impact of the blur.
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

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the slanted bar scene

% Only these eye models (not legrand) can accommodate
modelName = {'navarro','arizona'};
mm = 1;

% Choose 1 or 2 for Navarro or Arizona
thisSE = sceneEye('slantedEdge','eye model',modelName{mm});
thisSE.set('to',[0 0 0]);

thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);

% Set up the image
thisSE.set('fov',1);                % Field of view
thisSE.set('spatial samples',[256, 256]);  % Number of OI sample points
thisSE.set('film diagonal',2);          % mm
thisSE.set('rays per pixel',256);
thisSE.set('n bounces',2);

thisSE.set('lens density',0);       % Remove pigment. Yellow irradiance is harder to see.
thisSE.set('diffraction',false);
thisSE.set('pupil diameter',3);

% We run this for a closer distance to see how close the accommodation
% is to solving the new focal distance (object distance in focus).
oDistance = 1;
thisSE.set('object distance',oDistance);
fprintf('Object distance %.2f m\n',oDistance);

%{
 piAssetGeometry(thisSE.recipe);
 thisSE.recipe.show('lights');
%}
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

humanDocker = dockerWrapper.humanEyeDocker;
name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}

%% Diffraction should not matter

% Turn off diffraction.  With big pupil it shouldn't matter
thisSE.set('diffraction',false);

name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}

%% Diffraction with a small pupil should matter

thisSE.set('rays per pixel',1024);
thisSE.set('pupil diameter',1);
thisSE.set('diffraction',false);

name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
oi = thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}

%% Diffraction should matter.

% Make a direct comparison
thisSE.set('diffraction',true);

name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}

%%  Maybe we should be smoothing the curve at the edge?

thisSE.set('rays per pixel',1024);
thisSE.set('pupil diameter',0.5);
thisSE.set('diffraction',true);
name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}
%%  Maybe we should be smoothing the curve at the edge?

thisSE.set('diffraction',false);
name = sprintf('%s - pupil %.1f - diff %s',...
    modelName{mm},...
    thisSE.get('pupil diameter'),...
    thisSE.get('diffraction'));
thisSE.summary;
thisSE.piWRS('name',name,'docker wrapper',humanDocker);

%{
oi = ieGetObject('oi');
oi = piAIdenoise(oi);
oiPlot(oi,'illuminance hline',[128 128]);
set(gca,'xlim',[-30 30],'xtick',(-30:10:30));
title(oiGet(oi,'name'))
%}

%% END