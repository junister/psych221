function [status,result,dockercmd] = piDockerPBRT(varargin)
% Directly run pbrt in a Docker container
%
% Brief description
%   Uses the Docker Container to run pbrt directly
%
% Synopsis
%   [status,result,dockercmd] = piDockerPBRT(varargin)
%
% Inputs
%
% Optional key/val pairs
%   infile:   Full path to the input file
%
% Outputs
%   status    - 0 means success
%   result    - Text returned by the command
%   dockercmd - The docker command
%
% See also

% Example:
%{
%}

%% Parse

command = ieParamFormat(command);
varargin = ieParamFormat(varargin);

p = inputParser;

p.addParameter('infile','',@(x)(exist(x,'file')));
p.addParameter('outfile','',@ischar);

p.addParameter('dockerimage',dockerWrapper.localImage(),@ischar);

p.addParameter('verbose',true,@islogical);

% Maybe outfile should be handled separately as above.

% dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
p.parse(command,varargin{:});

dockerimage = p.Results.dockerimage;

% This is the pbrt recipe file
if ~isempty(p.Results.infile)
    % Extract working dir and file name for the docker
    infile = p.Results.infile;
    [workdir, fname, ext] = fileparts(infile);
    fname = [fname,ext];
end


if ~ispc
    runDocker = 'docker run -ti ';
else
    runDocker = 'docker run -i ';
end

% piDockerImgtool('denoise','infile',fullPathFile)
%{
            usage: imgtool denoise [options] <filename>
            options: options:
                --outfile <name>   Filename to use for the denoised image.
%}

basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];
cmd = sprintf('pbrt %s --outfile pbrt-%s', ...
    dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(fname));

dockercmd = sprintf(basecmd, ...
    dockerWrapper.pathToLinux(workdir), ...
    workdir, ...
    dockerWrapper.pathToLinux(workdir), ...
    dockerimage, ...
    cmd);



% Run dockercmd and show any result.  Maybe
[status,result] = system(dockercmd);
if p.Results.verbose || status ~= 0
    fprintf('Run command:  %s\n',cmd);
    fprintf('Status %d (0 is good)\n',status);
    if ~isempty(result)
        disp(result)
    end
end


end
