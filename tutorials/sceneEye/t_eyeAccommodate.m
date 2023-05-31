%% t_eyeAccommodate.m
%
% We recommend you go through t_eyeIntro.m before running
% this tutorial.
%
% This tutorial renders a retinal image of "slanted edge." We can then use
% this slanted bar to estimate the modulation transfer function of the
% optical system.
%
% We show the color fringing along the edge of the bar due to
% chromatic aberration. The calculation is done for different
% accommodations of the Navarro and Arizona eye models.
%
% Notes:  It may be that the assumed retinal distance for the eye
% models and this calculation differ.  When I sweep through the focal
% distances, I do not get the proper fringing when focal distance is
% set to object distance, and retinal 
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
% thisSE.set('focal distance',thisSE.get('object distance','m'));

thisSE.set('lens density',0);       % Remove pigment. Yellow irradiance is harder to see.
thisSE.set('diffraction',false);
thisSE.set('pupil diameter',3);

oDistance = 1;
thisSE.set('object distance',oDistance);
fprintf('Object distance %.2f m\n',oDistance);

% piAssetGeometry(thisSE.recipe);
% thisSE.recipe.show('lights');

%% Scene

% I checked multiple times and got tired of rendering this a lot.
%
%{
thisDockerGPU = dockerWrapper;
thisSE.set('use pinhole',true);
thisSE.piWRS('docker wrapper',thisDockerGPU,'name','pinhole');  % Render and show
%}

%% Render with model eye, varying diffraction setting

% Use model eye
thisSE.set('use optics',true);

thisSE.set('fov',1);                % Field of view

% This sets the chromaticAberrationEnabled flag and the integrator to
% spectral path.
% Now works in V4 - May 28, 2023 (ZL)
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);

thisSE.set('accommodation',1/oDistance);
thisSE.get('focal distance')

inFocusAcc = 1/oDistance;
delta = 0.15*inFocusAcc;

% thisSE.set('retina distance',16.32);  % Default
%{
For the Navarro eye, and an object far away (10m), the in focus retina
 distance is 16.32mm.
For the Arizona eye, and an object far away (10m), the in focus retina
 distance is more like 16.55mm.

For the Navarro eye, Foc D 1 m and Obj D 1 m match with Ret D 16.40
For the Arizona eye, Foc D 1 m and Obj D 1 m match with Ret D 16.55
%}

% For Arizona, when larger than default, we get a better agreement
% between the chromatic blur and the actual distance.
% I should check for Navarro, too.
%
% thisSE.set('retina distance',16.7);       
% We step the accommodation to see the blur change.
humanDocker = dockerWrapper.humanEyeDocker;
% for aa =  (-2*delta + inFocusAcc):2*delta:(2*delta + inFocusAcc)
for rr =  16.1:0.15:16.75
    % thisSE.set('accommodation',aa);
    thisSE.set('retina distance',rr);
    name = sprintf('%s Foc %.2f Obj %.2f Ret %0.2f',modelName{mm}(1:2),...
        thisSE.get('focal distance'),...
        oDistance,...
        thisSE.get('retina distance','mm'));
    thisSE.summary;
    oi = thisSE.piWRS('name',name,'docker wrapper',humanDocker,'show',true);
    % oi = ieGetObject('oi'); oi = piAIdenoise(oi); ,oiWindow(oi);
end

%% END