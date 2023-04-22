function thisDWrapper = humanEyeDocker()
%HUMANEYEDOCKER Get suitable docker Wrapper for human eye
%   Currently that means forcing CPU rendering
%   often on a remote and more powerful CPU
%
%   TBD: Add an options.remote so you can also get a local version

fprintf('Suggest using thisD.preset(''human eye'')\n');

thisDWrapper = dockerWrapper;
thisDWrapper.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
thisDWrapper.gpuRendering = 0;

end
