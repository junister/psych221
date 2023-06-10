%% v_piText
% 
% Validation for inserting text into a recipe
% 
% Make the double character instance work

%% Original way with textRender

thisR = piRecipeCreate('macbeth checker');
piMaterialsInsert(thisR,'name','wood-light-large-grain');
to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
str = 'Lorem';
pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
thisR = textRender(thisR, str,'letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
    'letterPosition',pos,'letterMaterial','wood-light-large-grain');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);

%% This now renders the same way as above

thisR = piRecipeCreate('macbeth checker');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);

piMaterialsInsert(thisR,'name','wood-light-large-grain');

% str = 'Lorem';
str = 'Lorem';
piTextInsert(thisR,str);
% thisR.show;

% Letter positions as above
to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
%}

% Letter sizes as in textRender
characterAssetSize = [.88 .25 1.23];
letterScale = [0.15,0.1,0.15] ./ characterAssetSize;

% Matching the rotate/translate/scale operations with textRender
for ii=1:numel(str)
    idx = piAssetSearch(thisR,'object name',['_',str(ii),'_']);
    thisR.set('asset',idx, 'material name','wood-light-large-grain');

    % This seems to match textRender
    thisR.set('asset',idx, 'rotate', [0,15,15]);
    thisR.set('asset',idx, 'rotate', [-90 00 0]);
    thisR.set('asset',idx, 'translate',pos(ii,:));
    thisR.set('asset',idx, 'scale', letterScale);
end
% thisR.show('objects');

% Need to understand this.  It renders with this, but I do not yet
% understand what all the different branch and instances are doing and how
% they know about one another.
%
% piObjectInstance(thisR);

piWRS(thisR);

%% Deal with instances

% Adding the instances alone changes nothing.  That's probably good.
piObjectInstance(thisR);

%%
thisR.show;
piWRS(thisR);

%%  

% Maybe this should be thisR.get('asset',idx,'top branch')
thisLetter = piAssetSearch(thisR,'object name','_L_uc');
p2Root = thisR.get('asset',thisLetter,'pathtoroot');
idx = p2Root(end);

% The 'position' seems to be a translation
[thisR, foo] = piObjectInstanceCreate(thisR, idx, 'position',[-0.1 0 0.0]);
thisR = piObjectInstanceCreate(thisR, idx, 'position',[0 0.1 0.0]);

piWRS(thisR);

%% END