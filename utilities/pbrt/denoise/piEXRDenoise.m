function [object, results, outputHDR] = piEXRDenoise(exrFileName,varargin)
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
% We have used the denoiser to clean up PBRT rendered images when we
% only use a small number of rays.  We use it for show, not for
% accurate simulations of scene or oi data.
%
% We may embed this denoiser in the PBRT docker image that can
% integrate with PBRT.  We are also considering the denoiser that is
% part of imgtool, distributed with PBRT.
%

%% Parse
p = inputParser;
p.addRequired('exrfilename',@(x)(isfile(x)));
p.addParameter('placebo',true);
p.parse(exrFileName, varargin{:});

%% Set up the denoiser path information and check

if ismac
    oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
elseif isunix
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
elseif ispc
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.0.1.x64.windows', 'bin');
else
    warning("No denoise binary found.\n")
end

if ~isfolder(oidn_pth)
    warning('Could not find the directory:\n%s',oidn_pth);
    return;
end

tic; % start timer for deNoise


%% NOW WE HAVE A "RAW" EXR FILE
% That we need to turn into pfm files.
% "regular" denoiser normalizes each channel, but not sure if we should?

%% Get needed data from the .exr file
% First, get channel info
eInfo = exrinfo(exrFileName);
eChannelInfo = eInfo.ChannelInfo;

% Need to read in all channels. I think we can do this in exrread() if we
% put them all in an a/v pair 
getChannels = [];
for ii = 1:numel(eChannelInfo.Properties.RowNames)
    %fprintf("Channel: %s\n", eChannelInfo.Properties.RowNames{ii});
    getChannels = [getChannels, convertCharsToStrings(eChannelInfo.Properties.RowNames{ii})];
end
eData(:, :, :, 1) = exrread(exrFileName, "Channels",getChannels);

exrData = [];
% We now have all the data in the eData array with the channel being the
% 3rd dimension, but with no labeling
for ii = 1:numel(eChannelInfo.Properties.RowNames)
        
% We  want to write out the radiance channels using their names into
% .pfm files, AFTER tripline them!
    if contains(convertCharsToStrings(eChannelInfo.Properties.RowNames{ii}), "Radiance")
        eData(:, :, ii, 2 ) = eData(:,:,ii,1);
        eData(:, :, ii, 3 ) = eData(:,:,ii,1);
        % WRITE PFM
        
    % Albedo is also 3 channels
    elseif contains(convertCharsToStrings(eChannelInfo.Properties.RowNames{ii}), "Albedo")
        fprintf("Write albedo here\n");
    % Normal should be a 3-channel output I think
    % but is xyz
    elseif contains( convertCharsToStrings(eChannelInfo.Properties.RowNames{ii}), "N")
        fprintf("Write Normal here\n");
    end

end

outputTmp = {};
DNImg_pth = {};
for ii = 1:numel(eChannelInfo.Properties.RowNames)
    % Currently use only the channel number
    % Could be an issue if we do multiple renders in parallel
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
