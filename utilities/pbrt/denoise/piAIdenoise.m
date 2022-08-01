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
%
% Runs executable for the Intel denoiser (oidn_pth).  The executable
% must be installed on your machine.
% 
% This is a Monte Carlo denoiser based on a trained model from intel
% open image denoise: 'https://www.openimagedenoise.org/'.  You can
% download versions for various types of architectures from 
%
% https://www.openimagedenoise.org/downloads.html
%
% We expect the directory location on a Mac to be
% 
%   fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
%
% Otherwise, we expect the oidnDenoise command to be in
%
%   fullfile(piRootPath, 'external', 'oidn-1.4.2.x86_64.linux', 'bin');
%
% We plan to update this program (piAIdenoise) to allow other paths
% and other versions in the future, after we get some experience with
% people using the method.
%
% We have used the denoiser to clean up PBRT rendered images when we
% only use a small number of rays.  We use it for show, not for
% accurate simulations of scene or oi data.
%
% We may embed this denoiser in the PBRT docker image that can
% integrate with PBRT.  We are also considering the denoiser that is
% part of imgtool, distributed with PBRT.
%
% See also
%   sceneWindow, oiWindow

%% Parse
p = inputParser;
p.addRequired('object',@(x)(isequal(x.type,'scene') || isequal(x.type,'opticalimage') ));
p.addParameter('quiet',false,@islogical);

p.parse(object,varargin{:});

quiet = p.Results.quiet;

%% Set up the denoiser path information and check

if ismac
    oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
elseif isunix
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
elseif ispc
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.windows', 'bin');
else
    warning("No denoise binary found.\n")
end

if ~isfolder(oidn_pth)
    error('Could not find the directory:\n%s',oidn_pth);
end


%%  Get the photon data

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

% Old code, no longer used. get normal
% if isfield(object.data,'normalMap') && ~isempty(object.data.normalMap)
%     normalFlag = 1;
%     normalmap = object.data.normalMap;
%     normal_pth = fullfile(piRootPath,'local','tmp_input_normal.pfm');
%     writePFM(normalmap, normal_pth);
% end

outputTmp = fullfile(piRootPath,'local','tmp_input.pfm');
DNImg_pth = fullfile(piRootPath,'local','tmp_dn.pfm');
newPhotons = zeros(rows, cols, chs);



%% Run it

if ~quiet, h = waitbar(0,'Denoising multispectral data...','Name','Intel denoiser'); end
for ii = 1:chs
    % For every channel, get the photon data, normalize it, and
    % denoise it
    img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));
    img_sp(:,:,2) = img_sp(:,:,1);
    img_sp(:,:,3) = img_sp(:,:,1);

    % Write it out into a temporary file
    writePFM(img_sp, outputTmp);
    cmd  = [oidn_pth, [filesep() 'oidnDenoise --hdr '], outputTmp,' -o ',DNImg_pth];
    
    % Run the executable.
    [status, results] = system(cmd);
    if status, error(results); end

    % Read the denoised data and scale it back up
    DNImg = readPFM(DNImg_pth);
    newPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));

    if ~quiet, waitbar(ii/chs, h,sprintf('Spectral channel: %d nm \n', wave(ii))); end
end
if ~quiet, close(h); end

%% Set the data into the object

switch object.type
    case 'scene'
        object = sceneSet(object,'photons',newPhotons);
    case 'opticalimage'
        object = oiSet(object,'photons',newPhotons);
end

% Clean up the temporary file.
if exist(DNImg_pth,'file'), delete(DNImg_pth); end
if exist(outputTmp,'file'), delete(outputTmp); end

end
