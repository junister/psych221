%% t_arealightSizeArray.m
%
%  * Change the size (scale) of an area light 
%  * Move the light closers and further from the target
%  * Change the spread of the light
%  * Combine a couple of area lights into an array
%  * Move the camera so that it looks at the area light array
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

%% Make an area light

% The light position is (0,0,0), which happens to be the camera position
area{1} = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','D65');
thisR.set('lights',area{1},'add');
thisR.show('lights');

% Rotate the light so it is pointing at the surface
thisR.set('light','area1','rotate',[0 180 0]);

% The light is very big so it illuminates the whole surface
piWRS(thisR,'name','big light');

%% Reduce the size of the light and its spread

thisR.set('light','area1','spread',10);
thisR.set('light','area1','shape scale',0.005);   % Five millimeters

piWRS(thisR,'name','small light');

%% Return the size

thisR.set('light','area1','shape scale',100);
piWRS(thisR,'name','restore size');

%% Create an array with different positions 

% Start fresh with the scene.  Not necessary, but ...
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'scale',0.25);   

% Add some surface textures.  For now make the surface white.
piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');

% Add the three area lights
area = cell(1,3);

% Triangular positions, a few millimeters off to the side of the
% camera
pos = [0.005 0 0; 
       0.100 0 0; 
       0.05 0.050 0];

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

piWRS(thisR);

%% Move the cube closer to the camera

thisR.set('asset',cubeID,'translate',[0 0 -0.5]);
piWRS(thisR);

%% Change the light size and compensate by scaling the SPD

% Start fresh with a small Cube
ieInit;
clear area;

% Start fresh with the scene.  Not necessary, but ...
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);
specScale = 50;

area{1} = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','D65', ...
    'specscale',specScale);
thisR.set('lights',area{1},'add');
thisR.set('light','area1','spread',5);  % Narrow spread so the size will be easier to see
thisR.set('light','area1','rotate',[0 180 0]);
thisR.show('lights');

% We cannot use the shape scale parameter as part of the create
% because it is a method, not a parameter.  That could be changed by
% adding it to piLightCreate for the area light.
thisR.set('light',area{1},'shape scale',0.1);

% Reduce the light's size a couple of times.  We change the SPD
% scaling and Shape scaling together.
scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));

thisR.set('light',area{1},'shape scale',0.3);
thisR.set('light',area{1},'specscale',specScale/(0.3)^2);
scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));

thisR.set('light',area{1},'shape scale',0.3);
thisR.set('light',area{1},'specscale',specScale/(0.3*0.3)^2);

scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));
%%