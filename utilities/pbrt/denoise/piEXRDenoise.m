function status = piEXRDenoise(exrFileName,varargin)
% A denoising method (AI based) that applies to multi-spectral HDR data
% tuned for Intel's OIDN
%
% Synopsis
%   <output exr file> = piAIdenoise(<input exr file>)
%
% Inputs
%   <exr  file>:
%
%   'channels': 'exr_radiance', 'exr_albedo', 'exr_all'
%   'filter': 'RT' (Default) | 'RTLightmap' (not clear whether this helps)
%
% Returns
%   <denoised exr file>
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

% Set to no error
status = 0;

%% Parse
p = inputParser;
p.addRequired('exrfilename',@(x)(isfile(x)));
p.addParameter('placebo',true);
p.addParameter('channels','');
p.addParameter('filter','RT'); % RTLightmap is also an option
p.parse(exrFileName, varargin{:});

% Generate file names for albedo and normal if we have them
[pp, nn, ee] = fileparts(p.Results.exrfilename);
albedoFileName = fullfile(pp, 'Albedo.pfm');
normalFileName = fullfile(pp, 'Normal.pfm');

% Decide whether to use additional data for denoising. There is improvement
% in detail but the process takes longer
if ismember(p.Results.channels, ['exr_albedo', 'exr_all'])
    useAlbedo = true;
else
    useAlbedo = false;
end
if ismember(p.Results.channels, ['exr_all'])
    useNormal = true;
else
    useNormal = false;
end

% only set filter flag if needed, to keep the command short
if ~isequal(p.Results.filter, 'RT')
    filterFlag = [' -f ' p.Results.filter ' '];
else
    filterFlag = '';
end

%% Set up the denoiser path information and check

oidn_Binary = 'oidnDenoise';
if ismac
    oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
elseif isunix
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
elseif ispc
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.0.1.x64.windows', 'bin');
    %oidn_Binary = 'oidnDenoise.exe';
end

if ~isfolder(oidn_pth)
    warning('Could not find the directory:\n%s',oidn_pth);
    status = -2;
    return;
end

% Add to path to shorten the batch command, otherwise it is too
% long to execute as a single system() call.
originalFolder = cd(oidn_pth);
baseCmd = oidn_Binary;
%baseCmd = fullfile(oidn_pth, "oidnDenoise");

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
radianceChannels = [];
albedoChannels = [];
normalChannels = [];
rgbChannels = [];
depthChannels = [];

% set command flags
commandFlags = [filterFlag ' --hdr '];

for ii = 1:numel(eChannelInfo.Properties.RowNames) % what about Depth and RGB!
    %fprintf("Channel: %s\n", eChannelInfo.Properties.RowNames{ii});
    channelName = convertCharsToStrings(eChannelInfo.Properties.RowNames{ii});
    if contains(channelName,'Radiance') % we always want radiance channels
        radianceChannels = [radianceChannels, channelName];
    elseif contains(channelName, 'Albedo')
        albedoChannels = [albedoChannels channelName]; % Blue, Green, Red
    elseif ismember(channelName, ["Nx", "Ny", "Nz"])
        normalChannels = [normalChannels, channelName];
    elseif ismember(channelName, ["R", "G", "B"])
        rgbChannels = [rgbChannels, channelName]; % Blue, Green, Red
    elseif ismember(channelName, ["Px", "Py", "Pz"])
        depthChannels = [depthChannels, channelName]; % Px, Py, Pz
    end
end

% Read radiance, normal and albedo data
radianceData(:, :, :, 1) = exrread(exrFileName, "Channels",radianceChannels);
if ~isempty(albedoChannels)
    albedoData = exrread(exrFileName, "Channels",albedoChannels);
    if useAlbedo % Denoise the albedo
        writePFM(albedoData, albedoFileName);
        [status, result] = system(strcat(baseCmd, commandFlags, " ", albedoFileName, " -o ",albedoFileName ));
        albedoFlag = [' --clean_aux --alb ' albedoFileName];
    else
        albedoFlag = '';
    end
else
    albedoFlag = '';
end
if ~isempty(normalChannels)
    normalData = exrread(exrFileName, "Channels",normalChannels);
    if useNormal
        writePFM(normalData,normalFileName);
        [status, result] = system(strcat(baseCmd, commandFlags, " ", normalFileName, " -o ",normalFileName ));
        normalFlag = [ ' --nrm ' normalFileName];
    else
        normalFlag = '';
    end
else
    normalFlag = '';
end
if ~isempty(depthChannels)
    depthData = exrread(exrFileName, "Channels",depthChannels);
end

% We now have all the data in the radianceData array with the channel being the
% 3rd dimension, but with no labeling
for ii = 1:numel(radianceChannels)
    % We  want to write out the radiance channels using their names into
    % .pfm files, AFTER tripline them!
    radianceData(:, :, ii, 2 ) = radianceData(:,:,ii,1);
    radianceData(:, :, ii, 3 ) = radianceData(:,:,ii,1);
    rFileNames{ii} = fullfile(pp, strcat(radianceChannels(ii), ".pfm"));

    % Write out the .pfm data as a grayscale for each radiance channel
    writePFM(squeeze(radianceData(:, :, ii, :)),rFileNames{ii}); % optional scale(?)
end



%% Run the Denoiser binary

denoiseFlags = strcat(" -v 0 ", albedoFlag, normalFlag, commandFlags, " "); % we need hdr for our scenes, -v 0 might help it run faster
for ii = 1:numel(radianceChannels)

    denoiseImagePath{ii} = rFileNames{ii};

    % With Albedo and Normal, the batch command gets too long
    % maybe we can fix it with cwd or addpath()?
    if isequal(ii, 1)
        cmd = strcat(baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii});
    else
        cmd = strcat(cmd , " && ", baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii} );
    end

    %cmd = strcat(baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii});
    %[status, results] = system(cmd);
    %if status, error(results); end
end

% IF BATCHING
%Run the full command executable once assembled
tic
[status, results] = system(cmd);
toc
if status, error(results); end


% NOW we have a lot of pfm files (one per radiance channel)
%     We can/could read them all back in and write them to an
%     output .exr file, unless there is something more clever

for ii = 1:numel(radianceChannels)

    % now read back the results
    denoisedData = readPFM(denoiseImagePath{ii});

    % In this case each PFM is a channel, that we want to re-assemble into
    % an output .exr file (I think)
    % This gives us data, but we don't have a labeled  channel for it
    % at this point
    denoisedImage(:, :, ii) = denoisedData(:, :, 1);

end

outputFileName = exrFileName;
completeImage = denoisedImage; % start with radiance channels
completeChannels = radianceChannels;
if ~isempty(albedoChannels)
    completeImage(:, :, end+1:end+3) = albedoData;
    completeChannels = [completeChannels albedoChannels];
end
if ~isempty(depthChannels)
    numDepth = numel(depthChannels);
    completeImage(:, :, end+1:end+numDepth) = depthData;
    completeChannels = [completeChannels depthChannels];
end
if ~isempty(normalChannels)
    completeImage(:, :, end+1:end+3) = normalData;
    completeChannels = [completeChannels normalChannels];
end

% Put the newly de-noised image back:
exrwrite(completeImage, exrFileName, "Channels",completeChannels);

% If we crash, user is stuck in the wrong place until we add a 
% try/catch block
cd(originalFolder);

fprintf("Denoised in: %2.3f\n", toc);
return

