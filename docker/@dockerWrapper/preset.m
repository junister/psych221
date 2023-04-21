function preset(presetName,varargin)
%PRESET - Set dockerWrapper prefs from a list of preset computer/GPUs
%
% Synopsis
%   dockerWrapper.preset(name,'save',[false])
%
% Brief
%   We support a number of remote rendering configurations at
%   vistalab. Specifying one of these returns a dockerWrapper
%   configured to run on a specific machine and GPU
%
% Input
%  presetName -
%   localGPU, localGPU-alt - we determine your local machine (host) and
%           configure for GPU 0 or 1 (-alt)
%
%   'remoteMux','remoteMux-alt' - Run on MUX either GPU 0 or GPU 1
%   'remoteOrange','remoteOrange-alt - Run on orange on GPU 0 or GPU 1
%
% See also
%

% TODO
%{
% To set up for the CPU on MUX you can use this
% humanEyeDocker
%
    thisDWrapper = dockerWrapper;
    thisDWrapper.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
    thisDWrapper.gpuRendering = 0;
%}
%{
% Maybe this should read as in these examples
%
   thisD = dockerWrapper.preset('machine','orange','gpu rendering',true,'which gpu',1);
   thisD = dockerWrapper.preset('machine','mux','gpu rendering',true);
   thisD = dockerWrapper.preset('machine','mux','gpu rendering',false);
   thisD = dockerWrapper.preset('machine','local','gpu rendering',false);
%}
presetName = ieParamFormat(presetName);

validNames = {'localgpu','localgpu-alt','remotemux','remotemux-alt','remoteorange','remoteorange-alt'}; 
if ~ismember(presetName,validNames)
    disp('Valid Names (allowing for ieParamFormat): ')
    disp(validNames);
    error('%s not in valid set %s\n',presetName); 
end

% TODO:  I am not sure we should change the MATLAB prefs for this.  I
% think we should leave the Matlab prefs alone but return a
% dockerWrapper that matches these conditions.  If we decide to set
% the prefs to match the current dockerWrapper, I think we have a
% method for that.  Or we could. (BW).
switch presetName
    % for use on Linux servers with their own GPU
    case {'localgpu', 'localgpu-alt'}
        % Render locally on Fastest GPU
        dockerWrapper.reset;
        rmpref('docker');
        dockerWrapper.setPrefs('gpuRendering', true);
        dockerWrapper.setPrefs('localRender',true);
        dockerWrapper.setPrefs('remoteResources',true);
        dockerWrapper.setPrefs('renderContext', 'default');

        % Different machines have diffrent GPU configurations
        [status, host] = system('hostname');
        if status, disp(status); end
        
        host = strtrim(host); % trim trailing spaces
        switch host
            case 'orange'
                dockerWrapper.setPrefs('localImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                switch presetName
                    case 'localgpu'
                        dockerWrapper.setPrefs('whichGPU', 1);
                    case 'localgpu-alt'
                        dockerWrapper.setPrefs('whichGPU', 0);
                end
            case {'mux', 'muxreconrt'}
                dockerWrapper.setPrefs('localImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux');
                switch presetName
                    case 'localgpu'
                        dockerWrapper.setPrefs('whichGPU', 0);
                    case 'localgpu-alt'
                        dockerWrapper.setPrefs('whichGPU', 1);
                end
            otherwise
                dockerWrapper.setPrefs('whichGPU',0);
        end
    case {'remotemux', 'remoteorange', 'remoteorange-alt', 'remotemux-alt'}
        % Render remotely on GPU
        dockerWrapper.reset;
        rmpref('docker');
        dockerWrapper.setPrefs('gpuRendering', true);
        dockerWrapper.setPrefs('localRender',false);
        dockerWrapper.setPrefs('remoteResources',true);

        % find our current user name -- seems like Matlab doesn't have a
        % function?
        userName = char(java.lang.System.getProperty('user.name'));
        % pick the correct context
        switch presetName
            case {'remotemux', 'remotemux-alt'}
                dockerWrapper.setPrefs('renderContext', 'remote-mux');
                dockerWrapper.setPrefs('remoteMachine', 'muxreconrt.stanford.edu');
                dockerWrapper.setPrefs('remoteRoot',['/home/' userName]);
            case {'remoteorange', 'remoteorange-alt'}
                dockerWrapper.setPrefs('renderContext', 'remote-orange');
                dockerWrapper.setPrefs('remoteMachine', 'orange.stanford.edu');
                dockerWrapper.setPrefs('remoteRoot',['/home/' userName]);
        end

        % also pick GPU and docker image
        switch presetName
            case 'remotemux'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux');
                dockerWrapper.setPrefs('whichGPU', 0);
            case 'remotemux-alt'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-volta-mux');
                dockerWrapper.setPrefs('whichGPU', 1);
            case 'remoteorange'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                dockerWrapper.setPrefs('whichGPU', 1);
            case 'remoteorange-alt'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                dockerWrapper.setPrefs('whichGPU', 0);
        end
end

