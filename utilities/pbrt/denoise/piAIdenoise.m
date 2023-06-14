function [object, results, outputHDR] = piAIdenoise(object,varargin)
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
%   useNvidia - try to use GPU denoiser if available
%
%   batch -- possible shell script -- TBD
%   interleave -- use multiple channels -- TBD
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

% Try using Nvidia GPU de-noiser
p.addParameter('useNvidia',false,@islogical);
p.addParameter('keepHDR',false); % return the EXR file

p.addParameter('batch',false); 
p.addParameter('interleave',false); 

p.parse(object,varargin{:});

quiet = p.Results.quiet;
keepHDR = p.Results.keepHDR;

doBatch = p.Results.batch;
useInterleave = p.Results.interleave;

%% Set up the denoiser path information and check

if ~p.Results.useNvidia
    if ismac
        oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
    elseif isunix
        oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
    elseif ispc
        oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.0.0.x64.windows', 'bin');
        
        % old version
        %oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.windows', 'bin');
    else
        warning("No denoise binary found.\n")
    end
else
    if ispc
        oidn_pth = fullfile(piRootPath, 'external', 'nvidia_denoiser.windows');
    else
        warning("Don't know if we have a binary yet\n");
    end
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

if p.Results.useNvidia
    outputTmp = fullfile(piRootPath,'local',sprintf('tmp_input_%05d%05d.exr',randi(1000),randi(1000)));
    DNImg_pth = fullfile(piRootPath,'local',sprintf('tmp_dn_%05d%05d.exr',randi(1000),randi(1000)));
else
    outputTmp = fullfile(piRootPath,'local',sprintf('tmp_input_%05d%05d.pfm',randi(1000),randi(1000)));
    DNImg_pth = fullfile(piRootPath,'local',sprintf('tmp_dn_%05d%05d.pfm',randi(1000),randi(1000)));
end

newPhotons = zeros(rows, cols, chs);


%% Run it

if ~quiet, h = waitbar(0,'Denoising multispectral data...','Name','Intel or Nvidia denoiser'); end
if useInterleave
    % adjacent channels doesn't look good
    % channels = 1:3:chs-1;
    % so maybe groups of 10?
    channels = 1:10;
else
    channels = 1:chs;
end
for ii = channels
    % For every channel, get the photon data, normalize it, and
    % denoise it
    img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));

    if p.Results.useNvidia
        exrwrite(img_sp, outputTmp);
        cmd  = [oidn_pth, [filesep() 'Denoiser --hdr -i '], outputTmp,' -o ',DNImg_pth];
    else
        % Write it out into a temporary file
        % For the Intel Denoiser,need to duplicate the channels
        if useInterleave
            % Experiment with using adjacent channels
            %img_sp(:,:,2) = photons(:,:,ii+1)/max2(photons(:,:,ii+1));
            %img_sp(:,:,3) = photons(:,:,ii+2)/max2(photons(:,:,ii+2));
            % Can also try skipping
             img_sp(:,:,2) = photons(:,:,ii+10)/max2(photons(:,:,ii+0));
             img_sp(:,:,3) = photons(:,:,ii+20)/max2(photons(:,:,ii+20));
        else
            img_sp(:,:,2) = img_sp(:,:,1);
            img_sp(:,:,3) = img_sp(:,:,1);
        end

        writePFM(img_sp, outputTmp);
        if ispc
            % since we have 2.0
            % Not sure whether we need to check for CUDA
            % or we will get it automatically
            qualityFlag = ' -q high ';

            % Set CUDA for testing
            % It picks it automatically, it turns out
            deviceFlag = '';% -d cuda ';
        else
            qualityFlag = '';
            deviceFlag = '';
        end
        cmd  = [oidn_pth, [filesep() 'oidnDenoise '], deviceFlag, qualityFlag, ' --hdr ',outputTmp,' -o ',DNImg_pth];
    end

    % Run the executable.
    tic
    [status, results] = system(cmd);
    toc
    if status, error(results); end

    % Read the denoised data and scale it back up
    if p.Results.useNvidia
        DNImg = exrread(DNImg_pth);
    else
        DNImg = readPFM(DNImg_pth);
    end

    newPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));
    if useInterleave % adjacent case
        newPhotons(:,:,ii+1) = DNImg(:,:,2).* max2(photons(:,:,ii+1));
        newPhotons(:,:,ii+2) = DNImg(:,:,3).* max2(photons(:,:,ii+2));
        % skip case
        newPhotons(:,:,ii+10) = DNImg(:,:,2).* max2(photons(:,:,ii+10));
        newPhotons(:,:,ii+20) = DNImg(:,:,3).* max2(photons(:,:,ii+20));
    end
    
    if ~quiet, waitbar(ii/chs, h,sprintf('Spectral channel: %d nm \n', wave(ii))); end
end

if p.Results.useNvidia
    exrwrite(newPhotons,DNImg_pth);
else
    warning("We don't export .pfm yet");
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
if ~keepHDR
    if exist(DNImg_pth,'file'), delete(DNImg_pth);
        outputHDR = '';
    end
else
    outputHDR = DNImg_pth;
end
if exist(outputTmp,'file'), delete(outputTmp); end

end
