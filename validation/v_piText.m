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

%%
thisR = piRecipeCreate('macbeth checker');
% thisR = piRecipeCreate('simple scene');

piMaterialsInsert(thisR,'name','wood-light-large-grain');

str = 'Lorem';
piTextInsert(thisR,str);
% thisR.show;

% Letter positions
%{
to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
%}

% {
pos = [ 0.04 -0.89 0.01;
0.06 -0.87 0.00;
0.09 -0.86 -0.00;
0.11 -0.84 -0.01;
0.15 -0.82 -0.02];
%}
% Letter sizes
characterAssetSize = [.88 .25 1.23];
letterScale = [0.15,0.1,0.15] ./ characterAssetSize;

for ii=1:numel(str)
    idx = piAssetSearch(thisR,'object name',['_',str(ii),'_']);
    thisR.set('asset',idx,'world position',pos(ii,:));
    thisR.set('asset',idx, 'scale', letterScale);
    thisR.set('asset',idx,'material name','wood-light-large-grain');
end
% thisR.show('objects');

piWRS(thisR);

piAssetGeometry(thisR);


%% Deal with instances
piObjectInstance(thisR);
thisR.show;


thisR = textRender(thisR, str,'letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
    'letterPosition',pos,'letterMaterial','wood-light-large-grain');

thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);

%% END