function opticalImage = piFlareApply(scene, varargin)
% Add lens flare to a scene/optical image.
%
% Synopsis:
%   opticalImage = piFlareApply(scene, varargin)
%
% Brief description:
%   Apply a 'flare' PSF to a scene and generate an optical image.
%
% Inputs:
%   scene: An ISET scene structure.
%
%
% Output:
%   opticalImage: An ISET optical image structure.
%
%{
sceneSize = 512;
scene = sceneCreate('point array',sceneSize, 128);
oi = piFlareApply(scene);
ip = piOI2IP(oi);
ipWindow(ip);
%}
%
%% Parse input
varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('scene', @(x)isequal(class(x),'struct'));
p.addParameter('numsidesaperture',8,@isinteger);
p.addParameter('focallength',4.5e-3); % Focal length (m)

p.parse(scene, varargin{:});

scene = p.Results.scene;
numSidesAperture = p.Results.numsidesaperture;
%%
%% Typical parameters for a smartphone camera.
% Nominal wavelength (m).
lambda = 550e-9;
% Focal length (m).
f = 4.5e-3;
% Pixel pitch on the sensor (m).
delta = 1e-6;
% Sensor size (width & height, m).
l = 1.5e-3;
% Simulation resolution, in both spatial and frequency domains.
res = l / delta;

% Compute defocus phase shift and aperture mask in the Fourier domain.
% Frequency range (extent) of the Fourier transform (m ^ -1).
lf = lambda * f / delta;
% Diameter of the circular low-pass filter on the Fourier plane.
df = 1e-3;
% Low-pass radius, normalized by simulation resolution.
rf_norm = df / 2 / lf;
[defocus_phase, aperture_mask] = GetDefocusPhase(res, rf_norm,'numSidesAperture',numSidesAperture);

% Wavelengths at which the spectral response is sampled.
num_wavelengths = 31;
wavelengths = linspace(400, 700, num_wavelengths) * 1e-9;

% generate the PSFs
aperture = RandomDirtyAperture(aperture_mask);
%   aperture = aperture_mask;

%% Random defocus.
defocus = 1;
psf_spectral = GetPsf(aperture, defocus_phase * defocus, ...
    wavelengths ./ lambda);

[height, width, channel] = size(scene.data.photons);
photons_fl = zeros(height, width, channel);
for ww = 1:31
    psf = psf_spectral(:,:,ww);
    psf = psf/sum(psf(:));
    photons_fl(:,:,ww) = ImageConvFrequencyDomain(scene.data.photons(:,:,ww), psf, 2 );
    %     photons_fl(:,:,ww) = conv2(scene_dn.data.photons(:,:,ww), psf,'same');
end
opticalImage = piOICreate(photons_fl);
%
end

