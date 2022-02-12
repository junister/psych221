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
p.addParameter('dockerimage',dockerWrapper.localImage(),@ischar);
p.addParameter('helpparameter','',@ischar);
p.addParameter('verbose',true,@islogical);

% dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
p.parse(command,varargin{:});

dockerimage = p.Results.dockerimage;

%% Switch on the cmds

% Read the exr file and convert into the same directory
if ~ispc
    runDocker = 'docker run -ti ';
else
    runDocker = 'docker run -i ';
end

switch command
    case 'makeequiarea'
        %  piDockerImgtool('make equiarea','infile',filename);
        infile = p.Results.infile;
        [workdir, fname, ext] = fileparts(infile);
        fname = [fname,ext];
        
        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];
        
        cmd = sprintf('imgtool makeequiarea %s --outfile equiarea-%s', ...
            dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(fname));
        dockercmd = sprintf(basecmd, dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), dockerimage, cmd);
    case 'help'
        % piDockerImgtool('help','help parameter','convert')
        basecmd = [runDocker ' %s %s'];
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
