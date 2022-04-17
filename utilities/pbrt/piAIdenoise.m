function [object, results] = piAIdenoise(object,varargin)
% A denoising method (AI based) that applies to scene photons
%
% Synopsis
%   [object, results] = piAIdenoise(object)
%
% Inputs
%   object:  An ISETCam scene or oi
%
% Optional key/value
%   quiet - Do not show the waitbar
%
% Returns
%   object: The ISETCam object (scene or optical image) with the photons
%           denoised is returned
%
% Description
%   This routine is to run a denoiser (oidn_pth) on rendered images when
%   we only use a small number of rays.  This denoiser makes the images
%   look better.  It is not used for true simulations of sensor data.
%
%   This is a Monte Carlo denoiser based on a trained model from intel open
%   image denoise: 'https://www.openimagedenoise.org/'.
%
%   Ultimately, this will become a docker image that can integrate with
%   PBRT.
%
% See also
%   sceneWindow, oiWindow
%
% Update History:
%   10/15/21    djc    Fixed Windows pathing

%% Parse
p = inputParser;
p.addRequired('object',@(x)(isequal(x.type,'scene') || isequal(x.type,'opticalimage')));
p.addParameter('quiet',false,@islogical);

p.parse(object,varargin{:});

quiet = p.Results.quiet;

%%  Get the data

% [rows, cols, chs] = size(object.data.photons);
switch object.type
    case 'opticalimage'
        wave = oiGet(object,'wave');
        photons = oiGet(object,'photons');
        [rows,cols,chs] = size(photons);
    case 'scene'
        wave = sceneGet(object,'wave');
        photons = sceneGet(object,'photons');
        [rows,cols,chs] = size(photons);
    otherwise
        error('Should never get here.  %s\n',object.type);
end
% % get normal
% if isfield(object.data,'normalMap') && ~isempty(object.data.normalMap)
%     normalFlag = 1;
%     normalmap = object.data.normalMap;
%     normal_pth = fullfile(piRootPath,'local','tmp_input_normal.pfm');
%     writePFM(normalmap, normal_pth);
% end

%% Set up the denoiser path information

if ismac
    oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
else
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.2.x86_64.linux', 'bin');
end

outputTmp = fullfile(piRootPath,'local','tmp_input.pfm');
DNImg_pth = fullfile(piRootPath,'local','tmp_dn.pfm');
NewPhotons = zeros(rows, cols, chs);

if ~quiet, h = waitbar(0,'Denoising multispectral data...','Name','Intel denoiser'); end
for ii = 1:chs
    img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));
    img_sp(:,:,2) = img_sp(:,:,1);
    img_sp(:,:,3) = img_sp(:,:,1);
    writePFM(img_sp, outputTmp);
    cmd  = [oidn_pth, [filesep() 'oidnDenoise --hdr '], outputTmp,' -o ',DNImg_pth];
    [~, results] = system(cmd);
    [status, results] = system(cmd);
    if status
        error(results);
    end

    DNImg = readPFM(DNImg_pth);
    NewPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));
    if ~quiet, waitbar(ii/chs, h,sprintf('Spectral channel: %d nm \n', wave(ii))); end
end
if ~quiet, close(h); end

object.data.photons = NewPhotons;

if exist(DNImg_pth,'file'), delete(DNImg_pth); end
if exist(outputTmp,'file'), delete(outputTmp); end
% if exist(normal_pth,'file'), delete(normal_pth); end

end
