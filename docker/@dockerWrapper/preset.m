function preset(presetName)
%PRESET Load dockerWrapper prefs from a list of presets

switch presetName
    % for use on Linux servers with their own GPU
    case {'localGPU', 'localGPU-alt'}
        % Render locally on Fastest GPU
        dockerWrapper.reset;
        rmpref('docker');
        dockerWrapper.setPrefs('gpuRendering', true);
        dockerWrapper.setPrefs('localRender',true);
        dockerWrapper.setPrefs('remoteResources',true);
        dockerWrapper.setPrefs('renderContext', 'default');

        % Different machines have diffrent GPU configurations
        [status, host] = system('hostname');
        host = strtrim(host); % trim trailing spaces
        switch host
            case 'orange'
                dockerWrapper.setPrefs('localImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                switch presetName
                    case 'localGPU'
                        dockerWrapper.setPrefs('whichGPU', 1);
                    case 'localGPU-alt'
                        dockerWrapper.setPrefs('whichGPU', 0);
                end
            case {'mux', 'muxreconrt'}
                dockerWrapper.setPrefs('localImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux');
                switch presetName
                    case 'localGPU'
                        dockerWrapper.setPrefs('whichGPU', 0);
                    case 'localGPU-alt'
                        dockerWrapper.setPrefs('whichGPU', 1);
                end
            otherwise
                dockerWrapper.setPrefs('whichGPU',0);
        end
    case {'remoteMux', 'remoteOrange', 'remoteOrange-alt', 'remoteMux-alt'}
        % Render remotely on GPU
        dockerWrapper.reset;
        rmpref('docker');
        dockerWrapper.setPrefs('gpuRendering', true);
        dockerWrapper.setPrefs('localRender',false);
        dockerWrapper.setPrefs('remoteResources',true);

        % pick the correct context
        switch presetName
            case {'remoteMux', 'remoteMux-alt'}
                dockerWrapper.setPrefs('renderContext', 'remote-mux');
                dockerWrapper.setPrefs('remoteMachine', 'muxreconrt.stanford.edu');
            case {'remoteOrange', 'remoteOrange-alt'}
                dockerWrapper.setPrefs('renderContext', 'remote-orange');
                dockerWrapper.setPrefs('remoteMachine', 'orange.stanford.edu');
        end

        % also pick GPU and docker image
        switch presetName
            case 'remoteMux'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux');
                dockerWrapper.setPrefs('whichGPU', 0);
            case 'remoteMux-alt'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-volta-mux');
                dockerWrapper.setPrefs('whichGPU', 1);
            case 'remoteOrange'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                dockerWrapper.setPrefs('whichGPU', 1);
            case 'remoteOrange-alt'
                dockerWrapper.setPrefs('remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
                dockerWrapper.setPrefs('whichGPU', 0);
        end
end

