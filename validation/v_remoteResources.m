% Validate whether we can render our scenes using remote resources

%{
% Read a simple car scene.  One car.  Skymap. Ground plane.  The car has a
% lot of parts, though.
fileName = fullfile(piRootPath, 'data/scenes/low-poly-taxi/low-poly-taxi.pbrt');
thisR = piRead(fileName);
thisR.set('skymap',fullfile(piRootPath,'data/skymaps','sky-rainbow.exr'));
thisR.show('objects');

% The light names are not right.  Debug why.
thisR.show('lights');

% We need a way to know the names of the objectBegin instances we have
% created.  Right now they are used as a reference object.  I think the
% objects have the slot isObjectInstance set to 0. Also, we are using the
% string '_I_' in the node name to indicate an instance.

% The object is called taxi, but it does not show up in the object list.
% Here we add an instance of the taxi object, which references all of the
% subparts.  We may not be handling this correctly in parseGeometryText
% because we end up with duplicates in the asset tree.
carName = 'taxi';
rotationMatrix = piRotationMatrix('z', -15);
position       = [-4 0 0];

% We do not want to call the unique names a lot. We run
% piObjectInstanceCreate a lot, and that's why uniquenames is held out.
thisR   = piObjectInstanceCreate(thisR, [carName,'_m_B'], ...
    'rotation',rotationMatrix, 'position',position);
thisR.assets = thisR.assets.uniqueNames;
%}
%{
n = thisR.get('n nodes')
for ii=1:n
    a =  thisR.get('asset',ii,'type')
    name = thisR.get('asset',ii,'name')
    switch a
        case 'branch'
            
        case 'object'
        case 'light'
        otherwise
            disp(a)
    end
end

%}
% Check for docker configuration 
ieInit;
if ~piDockerExists, piDockerConfig; end

%{
th
thisR.show('objects');
%}

% Working web scenes:
% Can we always use piRead to read back in the PBRT files written by
% piWrite?
% {
% kitchen - original debug ...
thisR = piRecipeDefault('scene name','Simple Scene');
thisR = piRecipeDefault('scene name','ChessSet');

% I may not have the edited version at home! (BW)
thisR = piRecipeDefault('scene name', 'kitchen');  % New/old.  

thisR = piRecipeCreate('cornell_box');
thisR = piRecipeCreate('Macbeth checker');

% This is really big (almost 1300 assets and 10K lines).
thisR = piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt');

piWRS(thisR,'remote resources',true);

out = thisR.get('outputfile');

newOut = fullfile(piRootPath, 'local', 'test', 'kitchen.pbrt');
newOut = fullfile(piRootPath, 'local', 'test', 'bistro-vespa.pbrt');

thisR.set('input file',out);
thisR.set('output file',newOut);
piWRS(thisR);

%}
%{
thisR = piRecipeDefault('scene name', 'contemporary-bathroom');

% Find the empty shapes and delete them
idx = thisR.get('objects');
for ii=numel(idx):-1:1
    s = thisR.get('assets',idx(ii),'shape');
    if isempty(s)
        fprintf('Deleting %d\n',idx(ii));
        thisR = thisR.set('asset',idx(ii),'delete');
    end
end
piWRS(thisR);

% Are there any empty shapes?  All black now.  Not sure why.
idx = thisR.get('objects');
for ii=numel(idx):-1:1
    s = thisR.get('asset',idx(ii),'shape');
    if isempty(s)
        disp(idx(ii))
    end
end

piWRS(thisR, 'remoteResources', true);
%}
% landscape
% bmw-m6 (although with a sleight-of-hand for the skymap)
% head (once skymap is copied over & remoteResources is used)
%
% Kind of working:)
% bistro -- needs the same skymap hack as bmw
%           but also looks really bad, so something else is up
%
% Not-working web scenes:
% contemporary-bathroom -- rendering issues
%
% Not-working web scenes that might not work with our pbrt-v4 piRead at all
%
%{
% Test via:
thisR = piRead(fullfile(piDirGet('data'),'scenes','web','pbrt-v4-scenes',<scenename>,<pbrtfile>);
piWRS(thisR);

OR can we simply render the pbrt file if it doesn't read? To test it:

%}

% sportscar: Vertex indices "indices" must be provided with bilinear patch mesh shape.
% clouds: piRead -> Error using piMaterialCreate
% crown: piRead -> Error using parseBlockTexture
%                  Cannot find file textures/arc/saphire_bump.png
% dambreak0&1: piWrite -> Error in piLightGet (line 91)
%                       elseif strcmpi(lght.type, 'infinite')
% explosion: piRead -> Error using piMaterialCreate
%               The value of 'type' is invalid. It must satisfy the function: @(x)(ismember(x,validmaterials)).
% disney-cloud: piRead -> Error using piMaterialCreate
%               The value of 'type' is invalid. It must satisfy the function: @(x)(ismember(x,validmaterials)).
% book: (Can't find texture file)
%
% Also noted: These scenes aren't in our pbrt-v4 download, so RecipeDefault can't load them:
% classroom 
% veach-ajar 
% villalights 
% livingroom
% yeahright
% sanmiguel
% white-room
% bedroom
% teapot-full
% etc...
%
% TBD:
% 
% bistro
% ...
%

% bunny has no light sources, need more code
%thisR = piRecipeDefault('scene name', 'bunny');
%piWRS(thisR, 'remoteResources', true);

thisR = piRead('arealight.pbrt');
piWRS(thisR, 'remoteResources', true);

% needs a light source?
%thisR = piRead('car.pbrt');
%piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'checkerboard');
piWRS(thisR, 'remoteResources', false);
%{
S = piRender(thisR);
sceneWindow(S);
%}
thisR = piRecipeDefault('scene name', 'ChessSet');
[r,s] = piWRS(thisR, 'remoteResources', true);

%{

  % We seem to have to call reset when we change the parameters

  setpref('docker','remoteMachine','muxreconrt.stanford.edu');
  setpref('docker','renderContext','remote-mux');
  setpref('docker','remoteImage','digitalprodev/pbrt-v4-gpu-ampere-mux');
  dockerWrapper.reset;
  dockerMux = getpref('docker');

  setpref('docker','remoteMachine','orange.stanford.edu');
  setpref('docker','renderContext','remote-orange');
  setpref('docker','remoteImage','digitalprodev/pbrt-v4-gpu-ampere-ti');
  dockerWrapper.reset;
  dockerOrange = getpref('docker');

  thisD = dockerWrapper;
  thisD.getPrefs;
%}

% needs light source
%thisR = piRecipeDefault('scene name', 'coordinate');
%piWRS(thisR, 'remoteResources', true);

% needs light source
%thisR = piRecipeDefault('scene name', 'cornell_box');
%piWRS(thisR, 'remoteResources', true);

% Note: This looks pretty black, probably because it needs a light?
thisR = piRecipeDefault('scene name', 'CornellBoxReference');
piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'lettersAtDepth');
% piWrite(thisR);
% s = piRender(thisR); sceneWindow(s);

piWRS(thisR, 'remoteResources', true);

% Needs a light source
%thisR = piRecipeDefault('scene name', 'MacBethChecker');
%piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'materialball');
piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'materialball_cloth');
piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'SimpleScene');
piWRS(thisR, 'remoteResources', true);

% No light source
%thisR = piRecipeDefault('scene name', 'slantedEdge');
%piWRS(thisR, 'remoteResources', true);

% No light source
%thisR = piRecipeDefault('scene name', 'sphere');
%piWRS(thisR, 'remoteResources', true);

thisR = piRecipeDefault('scene name', 'stepfunction');
piWRS(thisR, 'remoteResources', true);

%% Teapot Fails!
% with true or false Gets material2 not defined, although I can't see why
try
    thisR = piRecipeDefault('scene name', 'teapot');
    piWRS(thisR, 'remoteResources', true);
catch err
    fprintf("Teapot Failed with error %s!!! \n", err.message);
end

% TBD has an issue on Windows with fbx to pbrt
%thisR = piRecipeDefault('scene name', 'testplane');
%piWRS(thisR, 'remoteResources', false);


