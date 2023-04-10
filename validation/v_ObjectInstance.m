%% v_ObjectInstance
% Test ObjectInstance creation

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

thisR.show('objects');
piWRS(thisR,'remote resources',true);

%% End
