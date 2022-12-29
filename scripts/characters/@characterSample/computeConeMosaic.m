function [cMosaic, oi] = computeConeMosaic(obj, options)
%COMPUTECONEMOSAIC Compute the foveal response to a character sample
%   Used in creating data samples for reading recognition
% Returns both the computed cone mosaic and the oi used to generate it
%
% Parameters:
%
% Examples:
%
%
% D. Cardinal, Stanford University, 2022
%

arguments
    obj;
    options.name = obj.name; % assuming the object has a name
    options.fov = [1 1]; % default of 1 degree
end

%  Needs ISETBio -- and set parallel to thread pool for performance
if piCamBio
    warning('Cone Mosaic requires ISETBio');
    return
end
% Create an oi if we aren't passed one
if isequal(class(obj),'oi')
    oi=obj;
else
    scene = obj;
    oi = oiCreate('wvf human');

end

poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool('Threads');
end

% Create the coneMosaic object
% We want this to be about .35mm in diameter
% or 1 degree FOV
cMosaic = coneMosaic;
cMosaic.fov = options.fov; 
cMosaic.emGenSequence(50);

oi = oiCompute(oi, scene);
cMosaic.name = options.name;
cMosaic.compute(oi);
cMosaic.computeCurrent;


