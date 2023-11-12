%% t_arealightSizeArray.m
%
%  * Change the size (scale) of an area light 
%  * Move the light closers and further from the target
%  * Change the spread of the light
%  * Combine a couple of area lights into an array
%  * Move the camera so that it looks at the area light array
%
%


%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple flat surface for the scene

thisR = piRecipeCreate('flat surface');

% Remove the other lights
thisR.set('lights','all','delete');

%% Make an area light

% The light position is (0,0,0), which happens to be the camera position
area{1} = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','Velscope2023');
thisR.set('lights',area{1},'add');
thisR.show('lights');

% Rotate the light so it is pointing at the surface
thisR.set('light','area1','rotate',[0 180 0]);

% The light is very big so it illuminates the whole surface
thisR.set('name','Velscope Light');
piWRS(thisR, 'name', thisR.name);

%% Reduce the size and the spread

thisR.set('light','area1','spread',10);
thisR.set('light','area1','shape scale',0.005);   % Five millimeters

thisR.set('name','narrow Velscope');
piWRS(thisR, 'name', thisR.name);

%% Return the size

thisR.set('light','area1','shape scale',100);
thisR.set('name','shape scale 100');
piWRS(thisR,  'name', thisR.name);

%% Create an array with different positions 

% Start fresh with the scene.  Not necessary, but ...
thisR = piRecipeCreate('flat surface');

% Remove the other lights
thisR.set('lights','all','delete');

% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'scale',0.25);   

% Add some surface textures
piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');

% Add the three area lights
area = cell(1,3);

% Triangular positions, a few millimeters off to the side of the
% camera
pos = [0.005 0 0; 
       0.050 0 0; 
       0.025 0.010 0];

% Set some of the light parameters
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

thisR.set('name','3 lights plus room');
piWRS(thisR, 'name', thisR.name);

%% Move the cube closer to the camera

thisR.set('asset',cubeID,'translate',[0 0 -0.5]);
thisR.set('name','cube closer by .5m');
piWRS(thisR,  'name', thisR.name);

thisR.set('asset',cubeID,'translate',[0 0 -0.25]);
thisR.set('name','cube closer by another .25m');
piWRS(thisR,  'name', thisR.name);

%% Start again but illustrate changing the size of the light

% Start fresh with the scene.  Not necessary, but ...
thisR = piRecipeCreate('flat surface');

% Remove the other lights
thisR.set('lights','all','delete');

clear area;

area{1} = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','D65');
thisR.set('lights',area{1},'add');
thisR.set('light','area1','spread',5);  % Narrow spread so the size will be easier to see
thisR.set('light','area1','rotate',[0 180 0]);
thisR.show('lights');

% Rotate the light so it is pointing at the surface

% The light is very big so it illuminates the whole surface
piWRS(thisR,'mean luminance',-1,'render flag','rgb', ...
    'name','large light');

%% Change its size by half a couple of times

% Notice that in addition to seeing the light (because of its narrow
% spread), the luminance level changes
thisR.set('light',area{1},'shape scale',0.1);
piWRS(thisR,'mean luminance',-1,'render flag','rgb', ...
    'name','light size * .10');

thisR.set('light',area{1},'shape scale',0.3);
piWRS(thisR,'mean luminance',-1,'render flag','rgb', ...
    'name','light size by another * .3');

thisR.set('light',area{1},'shape scale',0.3);
piWRS(thisR,'mean luminance',-1,'render flag','rgb', ...
    'name', 'light size by another * .3');

%%