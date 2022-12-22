% Experiment with different backgrounds for characters
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Something still isn't quite right about the H and I assets
Alphabet_UC = 'ABCDEFGJKLMNOPQRSTUVWXYZ';
chartRows = 4;
chartCols = 6;

% Use the patches of the MCC as placeholders
thisR = piRecipeCreate('macbeth checker');

% Put our characters in front, starting at the top left
to = thisR.get('to') - [0.5 -0.28 -0.8];

% This needs to be changed to chart box size
horizontalDelta = 0.2;
verticalDelta = -.21;
letterIndex = 0;

letterSize = [0.12,0.1,0.12];
letterRotation = [0 0 0];

for ii = 1:chartRows
    for jj = 1:chartCols
        letterIndex = letterIndex + 1;
        letter = Alphabet_UC(letterIndex);
        % Move right based on ii, down based on jj, don't change depth for
        % now
        pos = to + [((jj-1) *horizontalDelta) ((ii-1)*verticalDelta) 0]; %#ok<SAGROW> 
        thisR = charactersRender(thisR, letter,'letterSize',letterSize,'letterRotation',letterRotation,'letterPosition',pos,'letterMaterial','wood-light-large-grain');
    end
end

thisR.set('name','Sample Character Backgrounds');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);