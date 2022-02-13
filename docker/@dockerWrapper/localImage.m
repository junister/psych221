function dockerImage = localImage()
%LOCALIMAGE Find the right local Docker image to use
%   Currently pbrt is architecture specific, so we need to launch the
%   correct one

thisCPU = cpuinfo; % grabbed from isetcam
switch thisCPU.CPUName
    % should include other ARM processors
    case 'Apple M1 Pro'
        dockerImage = '--platform linux/arm64 camerasimulation/pbrt-v4-cpu-arm:latest';

    otherwise
        dockerImage = '--platform linux/amd64 digitalprodev/pbrt-v4-cpu:latest';
end

