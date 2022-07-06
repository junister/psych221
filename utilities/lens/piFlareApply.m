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
p.addParameter('numsidesaperture',20);
p.addParameter('focallength',4.5e-3); % Focal length (m)
p.addParameter('pixelsize',1.5e-6); % Focal length (m)
p.addParameter('maxluminance',1e6); % max luminance for scene
p.addParameter('sensorsize',3e-3); % sensorSize;
p.addParameter('dirtaperture',true);
p.parse(scene, varargin{:});

scene = p.Results.scene;
numSidesAperture = p.Results.numsidesaperture;
% Focal length (m).
FL = p.Results.focallength;
% Pixel pitch on the sensor (m).
PixelSize = p.Results.pixelsize;
SensorSize = p.Results.sensorsize;
maxLuminance = p.Results.maxluminance;
DirtAperture = p.Results.dirtaperture;
%%
%% Typical parameters for a smartphone camera.
% Nominal wavelength (m).
lambda = 550e-9;
% Sensor size (width & height, m).
% l = 3e-3;
% Simulation resolution, in both spatial and frequency domains.
Resolution = SensorSize / PixelSize;

% Compute defocus phase shift and aperture mask in the Fourier domain.
% Frequency range (extent) of the Fourier transform (m ^ -1).
lf = lambda * FL / PixelSize;
% Diameter of the circular low-pass filter on the Fourier plane.
df = 1e-3;
% Low-pass radius, normalized by simulation resolution.
rf_norm = df / 2 / lf;
[defocus_phase, aperture_mask] = GetDefocusPhase(Resolution, rf_norm,'numSidesAperture',numSidesAperture);

% Wavelengths at which the spectral response is sampled.
num_wavelengths = 31;
wavelengths = linspace(400, 700, num_wavelengths) * 1e-9;

% generate the PSFs
aperture = aperture_mask;
if DirtAperture
    aperture = RandomDirtyAperture(aperture);
end
%% Random defocus.
defocus = 1;
psf_spectral = GetPsf(aperture, defocus_phase * defocus, ...
    wavelengths ./ lambda);

luminance = sceneGet(scene,'luminance');
maxLuminance = min(maxLuminance, max(luminance(:)));
[height, width, channel] = size(scene.data.photons);
photons_fl = zeros(height, width, channel);
for ww = 1:31
    psf = psf_spectral(:,:,ww);
    psf = psf/sum(psf(:));
    photons_wl = scene.data.photons(:,:,ww);
    photons_wl(luminance > maxLuminance) = (maxLuminance/max(luminance(:)))* photons_wl(luminance > maxLuminance);
    photons_fl(:,:,ww) = ImageConvFrequencyDomain(photons_wl, psf, 2 );
    %     photons_fl(:,:,ww) = conv2(scene_dn.data.photons(:,:,ww), psf,'same');
end
opticalImage = piOICreate(photons_fl,'focalLength',FL);
%
end

