function [oi, pupilMask, psf_spectral] = piFlareApply(scene, varargin)
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
% Description
%   The paper "How to Train Neural Networks for Flare Removal" by Wu et al.
%
% See also
%   

% Examples:
%{
sceneSize = 512;
scene = sceneCreate('point array',sceneSize, 512);
scene = sceneSet(scene,'fov',1);
scene = sceneSet(scene, 'distance',0.05);
sceneSampleSize = sceneGet(scene,'sample size','m');
[oi,pupilmask, psf] = piFlareApply(scene,...
                    'psf sample spacing', sceneSampleSize, ...
                    'numsidesaperture', 5, ...
                    'fnumber',5,...
                    'psfsize', 512, 'dirtylevel',0);

ip = piOI2IP(oi,'etime',1/10);
ipWindow(ip);
%}
%%
% Calculate the PSF using the complex pupil method.  This allows us to
% calculate the PSF with arbitrary aberrations that can be modeled as
% optical path difference in the pupil.
%% Parse input
varargin = ieParamFormat(varargin);
p = inputParser;

p.addRequired('scene', @(x)isequal(class(x),'struct'));
p.addParameter('psfsamplespacing',0.25e-6); % PSF sample spacing (m)
p.addParameter('pupilimagewidth', 1024); % square image is used (pixels)
p.addParameter('psfsize',0); % output psf size (pixels)

% number of blades for aperture, 0 for circular aperture.
p.addParameter('numsidesaperture',0);
p.addParameter('focallength',4.5e-3); % Focal length (m)
p.addParameter('dirtylevel',0);       % Bigger number is more dirt.
% p.addParameter('normalizePSF',true);  % whether normalize the calculatedPSF
p.addParameter('fnumber', 5); % F-Number

% some parameters for defocus
p.addParameter('objectdistance', 1.0); % object distance in meters.
p.addParameter('focusdistance', 1.0); % focus distance in meters.
p.addParameter('sensoroffset', 0); % sensor offset from main lens in meters

p.addParameter('wavelist', 400:10:700, @isnumeric); % (nm)

p.parse(scene, varargin{:});

psfsamplespacing = p.Results.psfsamplespacing;
focusDistance    = p.Results.focusdistance;
objectDistance   = p.Results.objectdistance;
sensorOffset     = p.Results.sensoroffset;
pupilImageWidth  = p.Results.pupilimagewidth;
psfOutSize       = p.Results.psfsize;
numSidesAperture = p.Results.numsidesaperture;
dirtylevel       = p.Results.dirtylevel;
focalLength      = p.Results.focallength;
fNumber          = p.Results.fnumber;

% normalizePSF     = p.Results.normalizePSF;
waveList         = p.Results.wavelist;

pupilDiameter   = focalLength / fNumber; % (m)

%%
[sceneHeight, sceneWidth, ~] = size(scene.data.photons);

oi = piOICreate(scene.data.photons, 'focalLength', focalLength, 'fNumber', fNumber);

oi = oiSet(oi,'photons',oiCalculateIrradiance(scene,oi));

offaxismethod = opticsGet(oi.optics,'off axis method');
switch lower(offaxismethod)
    case {'skip','none',''}
    case 'cos4th'
        oi = opticsCos4th(oi);
    otherwise
        fprintf('\n-----\nUnknown offaxis method: %s.\nUsing cos4th.',optics.offaxis);
        oi = opticsCos4th(oi);
end

% Pad the optical image to allow for light spread (code from isetcam)
padSize  = round([sceneHeight sceneWidth]/8);
padSize(3) = 0;
sDist = sceneGet(scene,'distance');
oi = oiPad(oi,padSize,sDist);

oiSize = oiGet(oi,'size');
oiHeight = oiSize(1); oiWidth = oiSize(2);

oi = oiSet(oi, 'wAngular', 2*atand((oiWidth*psfsamplespacing/2)/focalLength));

% Generate dirty aperture mask
if dirtylevel>0
    if oiWidth>oiHeight
        imgSize = oiWidth;
    else 
        imgSize = oiHeight;
    end
    dirtyApertrue = RandomDirtyAperture(imgSize, dirtylevel); % crop this into scene size
end

for ww = 1:numel(waveList)
    wavelength = waveList(ww) * 1e-9; % (m)

    pupilSampleStepX = 1 / (psfsamplespacing * oiWidth) * wavelength * focalLength;

    pupilSupportX = (-0.5: 1/oiWidth: 0.5-1/oiWidth) * pupilSampleStepX * oiWidth;
    
    pupilSampleStepY = 1 / (psfsamplespacing * oiHeight) * wavelength * focalLength;
    pupilSupportY = (-0.5: 1/oiHeight: 0.5-1/oiHeight) * pupilSampleStepY * oiHeight;

    [pupilX, pupilY] = meshgrid(pupilSupportX, pupilSupportY);

    pupilRadius = 0.5*pupilDiameter;

    pupilRadialDistance = sqrt(pupilX.^2 + pupilY.^2);
    %% wavefront aberration for defocus
    W2_object = -( sqrt(focusDistance^2 - pupilDiameter.^2/4 ) ...
        - sqrt( objectDistance.^2 - pupilDiameter^2/4 ) - ...
        (focusDistance - objectDistance) );

    W2_image = sensorOffset / (8*fNumber^2);

    pupilMask = pupilRadialDistance <= pupilRadius;

    if numSidesAperture>0
        maskDiamter = find(pupilMask(oiHeight/2,:));
        centerPoint = [oiWidth/2+1,oiHeight/2+1];
        % create n sides polygon
        pgon1 = nsidedpoly(numSidesAperture, 'Center', centerPoint, 'radius', floor(numel(maskDiamter)/2));
        % create a binary image with the polygon
        pgonmask = poly2mask(floor(pgon1.Vertices(:,1)), floor(pgon1.Vertices(:,2)), oiHeight, oiWidth);
        pupilMask = pupilMask.*pgonmask;
    end
    
    if dirtylevel>0
        pupilMask = pupilMask .* imresize(dirtyApertrue,[oiHeight, oiWidth]);
    end

    pupilRho = pupilRadialDistance./pupilRadius;

    % For defocus, the OPD is defined as a parabolic phase shift that gets
    % multiplied into the pupil mask.
    wavefront_object = W2_object.*pupilRho.^2/wavelength;
    wavefront_image = W2_image.*pupilRho.^2/wavelength;

    Wavefront = wavefront_image + wavefront_object;
    phase_term = exp(1i*2 * pi .*Wavefront);
    OPD = phase_term.*pupilMask;

    psfFnAmp = fftshift(fft2(ifftshift(OPD)));
    inten = psfFnAmp .* conj(psfFnAmp);    % unnormalized PSF.
    shiftedPsf = real(inten);

    PSF = shiftedPsf./sum(shiftedPsf(:));
    PSF = PSF ./ sum(PSF(:));

    psf_spectral(:,:,ww) = PSF;

    %% apply psf to scene
    photons_fl(:,:,ww) = ImageConvFrequencyDomain(oi.data.photons(:,:,ww), psf_spectral(:,:,ww), 2 );

end

oi = oiSet(oi,'photons',photons_fl);
% crop the zero paddings
scene_size = sceneGet(scene,'size');
oi_size = oiGet(oi,'size');
% crop oi to remove extra edge
oi = oiCrop(oi, [(oi_size(2)-scene_size(2))/2,(oi_size(1)-scene_size(1))/2, ...
    scene_size(2)-1, scene_size(1)-1]);

illuminance = oiCalculateIlluminance(oi);
oi = oiSet(oi,'illuminance',illuminance);

end

%% Below function is modified from google-flare code.
% https://github.com/google-research/google-research/tree/master/flare_removal

function im = RandomDirtyAperture(imagewidth, dirty_level)
% RandomDirtyAperture Synthetic dirty aperture with random dots and scratches.
%
% im = RandomDirtyAperture(mask)
% Returns an N x N monochromatic image emulating a dirty aperture plane.
% Specifically, we add disks and polylines of random size and opacity to an
% otherwise white image, in an attempt to model random dust and scratches. 
%
% TODO(qiurui): the spatial scale of the random dots and polylines are currently
%   hard-coded in order to match the paper. They should instead be relative to
%   the requested resolution, n.
%
% Arguments
%
% imagewidth: An [N, N]-logical matrix representing the aperture mask. Typically, this
%       should be a centered disk of 1 surrounded by 0.
%
% dirty_level: above or equal to 0.
% Returns
%
% im: An [N, N]-matrix of values in [0, 1] where 0 means completely opaque and 1
%     means completely transparent. The returned matrix is real-valued (i.e., we
%     ignore the phase shift that may be introduced by the "dust" and
%     "scratches").
%
% Required toolboxes: Computer Vision Toolbox.


n = imagewidth;
im = ones([n,n], 'single');

%% Add dots (circles), simulating dust.
num_dots = max(0, round(20 + randn * 5));
num_dots = round(num_dots * dirty_level);
max_radius = max(0, 5 + randn * 50);
for i = 1:num_dots
  circle_xyr = rand(1, 3, 'single') .* [n, n, max_radius];
  opacity = 0.5 + rand * 0.5;
  im = insertShape(im, 'FilledCircle', circle_xyr, 'Color', 'black', ...
                  'Opacity', opacity);
end

%% Add polylines, simulating scratches.
num_lines = max(0, round(20 + randn * 5));
num_lines = round(num_lines * dirty_level);
% max_width = max(0, round(5 + randn * 5));
for i = 1:num_lines
  num_segments = randi(16);
  start_xy = rand(2, 1) * n;
  segment_length = rand * 600;
  segments_xy = RandomPointsInUnitCircle(num_segments) * segment_length;
  vertices_xy = cumsum([start_xy, segments_xy], 2);
  vertices_xy = reshape(vertices_xy, 1, []);
  width = randi(5);
  % Note: the 'Opacity' option doesn't apply to lines, so we have to change the
  % line color to achieve a similar effect. Also note that [0.5 .. 1] opacity
  % maps to [0.5 .. 0] in color values.
  color = rand * 0.5;
  im = insertShape(im, 'Line', vertices_xy, 'LineWidth', width, ...
                   'Color', [color, color, color]);
end

im = rgb2gray(im);

end

function xy = RandomPointsInUnitCircle(num_points)
r = rand(1, num_points, 'single');
theta = rand(1, num_points, 'single') * 2 * pi;
xy = [r .* cos(theta); r .* sin(theta)];
end