function renderString = piDockerRemoteInit(varargin)
%Initialize the docker preference for remote execution
%
% These are the key/value options that we pass in piRender when
% running with the GPU
%
% This persists across Matlab sessions.  So you don't need to run it
% every time.
%

%% Example
%{
  s = piDockerRemoteInit;
  s{8}
%}
p = inputParser;   
renderString = {'gpuRendering', true, ...
    'remoteMachine', 'muxreconrt.stanford.edu',...
    'renderContext', 'wandell-v4',...
    'remoteImage',  'digitalprodev/pbrt-v4-gpu-ampere-mux-shared', ...
    'remoteRoot','/home/wandell', ...
    'remoteUser', 'wandell', ...
    'whichGPU', 0};

% 'localRoot', <for WSL>, ...   % Not needed on MacOS

setpref('docker', 'renderString', renderString);
getpref('docker', 'renderString')   % Check

setpref('docker','verbosity', 1)

end
