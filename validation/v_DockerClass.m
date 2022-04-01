function success = v_DockerClass()
% Validate our new Docker class

    % Example of what we need to generate prior to running:
    %     'docker run -ti --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt'
    %   "docker run -i --rm -w /sphere -v C:/iset/iset3d-v4/local/sphere:/sphere camerasimulation/pbrt-v4-cpu pbrt --outfile renderings/sphere.exr sphere.pbrt"

    % cd([piRootPath '/local']);

    %% THIS WAS FOR THE INITIAL WINDOWS ONLY VERSION OF THE CLASS
    % It has not been updated ...
    
    ourDocker = dockerWrapper();
    ourDocker.workingDirectory = '/sphere';
    ourDocker.localVolumePath = 'c:/iset/iset3d-v4/local/sphere';
    ourDocker.targetVolumePath = '/sphere';
    ourDocker.inputFile = 'sphere.pbrt';
    ourDocker.outputFile = 'renderings/sphere.exr';

    success = ourDocker.run();
end
