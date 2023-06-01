%% t_filmResize
%
% Illustrate the impact of changing the aspect ratio and sampling
% properties of a scene.
%
% See also

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Illustrate with chess set

% The starting configuration.
thisR = piRecipeCreate('chess set');

% The camera parameters.  10 mm film diag, 320 x 320 samples
thisR.summarize('camera');

piWRS(thisR);

fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%% Look around with a bigger film diagonal for a momoent

% For a pinhole camera, should changing the film size also change the
% field of view?  Definitely if the film distance does not change.
% But it the @recipe logic changes the film distance with the
% film diagonal, preserving the field of view.
thisR.set('film diagonal',10);  % mm
thisR.get('film distance','mm')

% What happens if we change the distance, but not the diagonal.  Do we
% get a change in the field of view?

thisR.set('film distance',4.3e-3); % m
thisR.get('film diagonal','mm')
thisR.get('dfov')

thisR.set('film distance',2*4.3e-3); % m
thisR.get('film distance','mm')

thisR.get('film diagonal','mm');
thisR.get('fov')

thisR.summarize('camera');
%{
Same number of samples, bigger film, so sample spacing increases.
%}

piWRS(thisR);

fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%% Changing the number of samples

% Initially 320 x 320
ss = thisR.get('spatial samples');

% Samples are (X,Y) in PBRT
thisR.set('spatial samples',round([ss(1),ss(2)/2]));

thisR.summarize('camera');
%{
The sample spacing has increased.  The film diagonal is the same.  The
sample spacing increased because the diagonal now refers to a
rectangle (320 x 160), not the original 320 x 320 square. So when we
derive the spacing, it is no longer preserved.
%}

% This is what the image looks like
piWRS(thisR);

fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));


%% Doubling the original resolution

% 640 x 640
thisR.set('spatial samples',round(2*ss));

thisR.summarize('camera');
%{
Higher sampling density (sample spacing decreases). The film diagonal
is the same.  The field of view is the same.
%}
piWRS(thisR);

fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%%  An extreme case of generating a line sample 
%
% TG does this for speed, sometimes, say in calculating an edge spread
%
thisR.set('spatial samples',round([ss(1),32]));

thisR.summarize('camera');
%{
The sample spacing is very large because the 10 mm diagonal is along
the line; when the image was square the horizontal distance was
smaller so the sample spacing was smaller. The horizontal field of
view is the same.

%}
piWRS(thisR);

fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%%

