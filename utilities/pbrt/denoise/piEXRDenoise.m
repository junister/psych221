function [object, results, outputHDR] = piEXRDenoise(object,varargin)
% A denoising method (AI based) that applies to multi-spectral HDR data
% tuned for Intel's OIDN
%
% Synopsis
%   TBD = piAIdenoise(<exr file>)
%
% Inputs
%   <exr  file>:
%
% Optional key/value
%   quiet - Do not show the waitbar
%
%   batch -- use shell script
%
% Returns
%   ??
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
% Linux, we expect the oidnDenoise command to be in
%
%   fullfile(piRootPath, 'external', 'oidn-1.4.2.x86_64.linux', 'bin');
%
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
p.addRequired('filename',@(x)(isfile(x)));
p.parse(object,varargin{:});

%% Set up the denoiser path information and check

if ~p.Results.useNvidia
    if ismac
        oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
    elseif isunix
        oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
    elseif ispc
        % switch to using the version in our path, to make updates simpler
        oidn_pth = '';

    else
        warning("No denoise binary found.\n")
    end
end

if ~isempty(oidn_pth) && ~isfolder(oidn_pth)
    error('Could not find the directory:\n%s',oidn_pth);
end

tic; % start timer for deNoise

%%  Get the photon data

%% EXCEPT NOW WE HAVE THE "RAW" EXR FILE
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

outputTmp = {};
DNImg_pth = {};
for ii = 1:chs
    % see if we can use only the channel number
    % would be an issue if we do multiple renders in parallel
    outputTmp{ii} = fullfile(piRootPath,'local',sprintf('tmp_input-%d.pfm',ii));
    DNImg_pth{ii} = fullfile(piRootPath,'local',sprintf('tmp_dn-%d.pfm',ii));
end

% Empty array to store results
newPhotons = zeros(rows, cols, chs);

%% Run the Denoiser binary

channels = 1:chs;



for ii = channels
    % For every channel, get the photon data, normalize it, and
    % denoise it
    img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));
    img_sp(:,:,2) = photons(:,:,ii)/max2(photons(:,:,ii));
    img_sp(:,:,3) = photons(:,:,ii)/max2(photons(:,:,ii));

    % Write all the temp files at once
    % maybe do a parfor once this works!
    writePFM(img_sp, outputTmp{ii});

    % might have to be different on PC where we can't necessarily
    % chain commands with ';' or "&&'
    % maybe try wsl??
    baseCmd = fullfile(oidn_pth, 'oidnDenoise --hdr ');

    if isequal(ii, 1)
        cmd = [baseCmd, outputTmp{ii},' -o ', DNImg_pth{ii}];
    else
        cmd = [cmd , ' && ', baseCmd, outputTmp{ii},' -o ', DNImg_pth{ii} ];
    end
end
%Run the full command executable once assembled
%tic
[status, results] = system(cmd);
%toc
if status, error(results); end

for ii = channels
    % now read back the results
    DNImg = readPFM(DNImg_pth{ii});
    newPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));
    delete(DNImg_pth{ii});
    delete(outputTmp{ii});
end




%% Set the data into the object
%% REWRITE
switch object.type
    case 'scene'
        object = sceneSet(object,'photons',newPhotons);
    case 'opticalimage'
        object = oiSet(object,'photons',newPhotons);
end


fprintf("Denoised in: %2.3f\n", toc);
