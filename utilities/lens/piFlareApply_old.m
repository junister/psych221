function [opticalImage, aperture, psf_spectral] = piFlareApply_old(scene, varargin)
%% Will Remove This Later
% Add lens flare to a scene/optical image.
%
% Synopsis:
%   [opticalImage, aperture]  = piFlareApply(scene, varargin)
%
% Brief description:
%   Apply a 'flare' PSF to a scene and generate an optical image.
%
% Inputs:
%   scene: An ISET scene structure.
%
% Optional Key/val pairs
%  num sides aperture
%  focal length
%  pixel size
%  max luminance
%  sensor size
%  dirt aperture
%  dirty level
%
% Output:
%   opticalImage: An ISET optical image structure.
%   aperture:  Scratched aperture
%   psf_spectral -
%
%{
sceneSize = 512;
scene = sceneCreate('point array',sceneSize, 128);
sceneWindow(scene);
[oi,aperture] = piFlareApply(scene,'numsidesaperture',4,'dirty level',2);
oiWindow(oi);

ip = piOI2IP(oi);
ipWindow(ip);
ieNewGraphWin; imagesc(aperture); colorbar;
%}
%{
sceneSize = 64;
scene = sceneCreate('point array',sceneSize, 32);
scene = sceneSet(scene,'fov',1);

% What is the size of the aperture?
% What is the sample spacing of the psf?
[oi, aperture, psf] = piFlareApply(scene,'num sides aperture',100,'dirty aperture',false);
val = airyDisk(thisWave, fNumber, varargin)

%}
%
%% Parse input
varargin = ieParamFormat(varargin);
p = inputParser;

p.addRequired('scene', @(x)isequal(class(x),'struct'));
p.addParameter('psfsamplestep',1e-6); % PSF sample step (m)
p.addParameter('numsidesaperture',20);
p.addParameter('focallength',4.5e-3); % Focal length (m)
p.addParameter('pixelsize',1e-6);   % Pixel size (m)
p.addParameter('sensorsize',1e-3);    % sensorSize (m)
p.addParameter('dirtyaperture',true);
p.addParameter('dirtylevel',1);       % Bigger number is more dirt.

p.parse(scene, varargin{:});

scene = p.Results.scene;
% sceneGet(scene,'sample size','um')
PSFSampleStep = p.Results.psfsamplestep;
numSidesAperture = p.Results.numsidesaperture;

% Focal length (m).
focalLength = p.Results.focallength;

% Pixel pitch on the sensor (m).
PixelSize     = p.Results.pixelsize;
SensorSize    = p.Results.sensorsize;
DirtyAperture = p.Results.dirtyaperture;
dirty_level   = p.Results.dirtylevel;
%%
%% Typical parameters for a smartphone camera.

% Nominal wavelength (m).
lambda = 550e-9;

% Sensor size (width & height, m).
% l = 3e-3;
% Simulation resolution, in both spatial and frequency domains.
Resolution = SensorSize / PixelSize;   % Number of pixels

% Frequency range (extent) of the Fourier transform (m ^ -1).
% This is sampling limit related?  2 / PixelSize is the Nyquist
% frequency.   Not sure what this is.
lf = lambda * focalLength / PixelSize ;

pupilSampleStep = lf/Resolution;
% Diameter of the circular low-pass filter on the Fourier plane.
% Why is this a fixed number?
df = 1e-3;

% Low-pass radius, normalized by simulation resolution.
rf_norm = df / 2 / lf;

% Compute defocus phase shift and aperture mask in the Fourier domain.
[defocus_phase, aperture_mask] = GetDefocusPhase(Resolution, rf_norm, 'numSidesAperture', numSidesAperture);

% Wavelengths at which the spectral response is sampled.
num_wavelengths = 31;
wavelengths = linspace(400, 700, num_wavelengths) * 1e-9;

% generate the PSFs
aperture = aperture_mask;
if DirtyAperture
    aperture = RandomDirtyAperture(aperture, dirty_level);
end
%% Random defocus.
defocus = 1;

psf_spectral = GetPsf(aperture, defocus_phase * defocus, ...
    wavelengths ./ lambda);

[height, width, channel] = size(scene.data.photons);
photons_fl = zeros(height, width, channel);
for ww = 1:31
    psf = psf_spectral(:,:,ww);
    psf = psf/sum(psf(:));
    photons_wl = scene.data.photons(:,:,ww);
    photons_fl(:,:,ww) = ImageConvFrequencyDomain(photons_wl, psf, 2 );
    %     photons_fl(:,:,ww) = conv2(scene_dn.data.photons(:,:,ww), psf,'same');
end

opticalImage = piOICreate(photons_fl,'focalLength',focalLength);
opticalImage = oiSet(opticalImage, 'wAngular', 2*atand((SensorSize/2)/focalLength));
%
end

