%% t_arealightArray.m
%
%  * Create a triangular array of area lights
%  * Move the surface closer to the lights to see them
%  * Create a circular array of lights
%
% See also
%  t_arealight*


%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple flat surface for the scene

% The recipe has no light
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'scale',0.25);   

% Add some surface textures.  For now make the surface white.
piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');

% The three area lights
area = cell(1,3);

% Triangular positions, a few millimeters off to the side of the
% camera
pos = [0.005 0 0; 
       0.100 0 0; 
       0.05 0.050 0];

% Create and set the light parameters
for ii=1:3
    area{ii} = piLightCreate(sprintf('area-%d',ii),...
        'type','area',...
        'spd spectrum','D65.mat');
    thisR.set('light',area{ii},'add');
    thisR.set('light',area{ii},'translate',pos(ii,:));
    thisR.set('light',area{ii},'shape scale',0.005);   % 5 mm size
    thisR.set('light',area{ii},'rotate',[0 180 0]);    % Don't ask
    thisR.set('light',area{ii},'spread',5);            % 
    thisR.set('light',area{ii},'specscale',100);       % Brighten it
end

% Add an ambient light so we can see the surface where this light does
% NOT shine.
thisR.set('skymap','room.exr');
    thisR.set('light','room_L','rotate',[0 180 0]);    % Don't ask

piWRS(thisR);

%% Move the cube closer to the camera

% This makes it easier to see the three light sources
thisR.set('asset',cubeID,'translate',[0 0 -0.5]);
piWRS(thisR);

%% Create a ring of light sources

% Make the lights.  They will be in a circle around the camera.
% The camera is pointed in this direction.
direction = thisR.get('fromto');
[pts, radius] = piRotateFrom(thisR, direction, ...
    'n samples',nLights+1, ...
    'radius',velscopeRadius,...
    'show',false);


%%