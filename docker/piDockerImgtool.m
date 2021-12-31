function [status,result] = piDockerImgtool(command,varargin)
% Use imgtool for various PBRT related tasks 
%
% Synopsis
%   [status,result] = piDockerImgtool(command,varargin)
%
% Inputs
%   command:  The imgtool command.  Options are
%
% Optional key/val pairs
%   infile:   Full path to the input file
%   msparms:   albedo, elevation, outfile, turbidity, resolution
%
% Uses the Docker Container to execuate
%
%   piDockerImgtool('help')
%   piDockerImgtool('equiarea','infile',fullpathname);
%   piDockerImgtool('makesky','infile', fullpathname);
% 
%  imgtool makeequiarea old.exr --outfile new.exr
%
% See also
%

%{
% Other imgtool commands
%
% imgtool convert
% imgtool makesky
% imgtool denoise-optix noisy.exr --outfile denoised.exr
% imgtool makeequiarea old.exr --outfile new.exr
%
%}
% Example:
%{
   piDockerImgtool('help')
   [~,result] = piDockerImgtool('help','help parameter','convert');
%}
%{
infile = '20060807_wells6_hd.exr';
infile = 'room.exr';
infile = 'brightfences.exr';
infile = which(infile);
data = piDockerImgtool('makeequiarea','infile',infile)
%}
%{
exrfile = 'wtn-texture3-grass.exr'
exrfile = 'wtn-hurricane2.exr';
exrfile = which(exrfile);
piDockerImgtool('makeequiarea','infile',exrfile);

%}

%% Parse

command = ieParamFormat(command);
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('command',@(x)(ismember(x,{'makesky','makeequiarea','help'})));
p.addParameter('infile','',@ischar);
p.addParameter('dockerimage','camerasimulation/pbrt-v4-cpu:latest',@ischar);
p.addParameter('helpparameter','',@ischar);
p.addParameter('verbose',true,@islogical);

% dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
p.parse(command,varargin{:});

dockerimage = p.Results.dockerimage;

%% Switch on the cmds

% Read the exr file and convert into the same directory

switch command
    case 'makeequiarea'
        %  piDockerImgtool('make equiarea','infile',filename);
        infile = p.Results.infile;
        [workdir, fname, ext] = fileparts(infile);
        fname = [fname,ext];
        
        basecmd = 'docker run -ti --workdir=%s --volume="%s":"%s" %s %s';
        
        cmd = sprintf('imgtool makeequiarea %s --outfile equiarea-%s',fname,fname);
        dockercmd = sprintf(basecmd, workdir, workdir, workdir, dockerimage, cmd);
    case 'help'
        % piDockerImgtool('help','help parameter','convert')
        basecmd = 'docker run -ti %s %s';
        if isempty(p.Results.helpparameter)
            cmd = sprintf('imgtool ');
        else
            cmd = sprintf('imgtool help %s ',p.Results.helpparameter);
        end
        dockercmd = sprintf(basecmd, dockerimage, cmd);
    case 'makesky'
      %{        
        % usage: imgtool makesky [options] <filename>
        options:
        
        --albedo <a>       Albedo of ground-plane (range 0-1). Default: 0.5
        
        --elevation <e>    Elevation of the sun in degrees (range 0-90). Default: 10
        
        --outfile <name>   Filename to store environment map in.
        
        --turbidity <t>    Atmospheric turbidity (range 1.7-10). Default: 3
        
        --resolution <r>   Resolution of generated environment map. Default: 2048
       %}              
        % piDockerImgtool('makesky', ... params ...)
        disp('NYI')
    case 'denoise-optix'
        % piDockerImgtool('denoise-optix','infile',fullPathFile)
        disp('NYI')
end

% Run it and show any result.  Maybe
[status,result] = system(dockercmd);
if p.Results.verbose
    fprintf('Status %d (0 is good)\n',status);
    if ~isempty(result)
        disp(result)
    end
end

        
end
%{
if ~ispc
    % dockercmd = sprintf(basecmd, workdir, workdir, workdir, dockerimage, cmd);
    [status,result] = system(dockercmd,'-echo');
else
    ourDocker = dockerWrapper();
    ourDocker.command = ['imgtool convert --exr2bin ' channelname];
    ourDocker.dockerImageName = dockerimage;
    ourDocker.localVolumePath = indir;
    ourDocker.targetVolumePath = indir;
    ourDocker.inputFile = infile;
    ourDocker.outputFile = ''; % imgtool uses a default
    ourDocker.outputFilePrefix = '';
    
    [status, result] = ourDocker.runCommand();
end

if status
    disp(result);
    error('EXR to Binary conversion failed.')
end
filelist = dir([indir,sprintf('/%s_*',fname)]);

% if there are both depth and radiance files
% (on Windows at least) the Radiance files aren't
% always listed first, so we need to find one to
% get our base name
baseName = '';
dataFile = '';
for ii = 1:numel(filelist)
    if isequal(baseName, '') && ~isempty(strfind(filelist(ii).name, channelname))
        dataFile = filelist(ii);
        baseName = strsplit(filelist(ii).name,'.');
        nameparts = strsplit(filelist(ii).name,'_');
        Nparts = numel(nameparts);
        height = str2double(nameparts{Nparts-2});
        width= str2double(nameparts{Nparts-1});
    end
end

if strcmp(channelname,'Radiance')

    for ii = 1:31
        filename = fullfile(indir, [baseName{1},sprintf('.C%02d',ii)]);

        % On windows suffix might not exist?
        if ~isfile(filename)
            filename = fullfile(indir, baseName{1});
        end
        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        try
            data(:,:,ii) = reshape(serializedImage, height, width, 1);
        catch
            warning('Error reshaping radiance data.');
            pause;
        end
        fclose(fid);
        delete(filename);
    end
else
        filename = fullfile(indir, baseName{1});
        [fid, message] = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        data = reshape(serializedImage, height, width, 1);
        fclose(fid);
        delete(filename);
end
    
end
%}
