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

% For a pinhole camera, we store the FOV.  We do not store film
% distance
thisR.get('film distance','mm')

% But we do store the film size in film diagonal, strangely.
thisR.get('film diagonal','mm')

% What happens if we change the distance, but not the diagonal.  Do we
% get a change in the field of view?
thisR.get('dfov')

thisR.set('dfov',30);
thisR.get('dfov')

thisR.summarize('camera');

piWRS(thisR);
fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%% If we change the film size, the sample spacing changes
% but the FOV stays the same

% When we are in pinhole mode, we should not have a film diagonal.
thisR.set('film diagonal',5);
thisR.summarize('camera');
piWRS(thisR);
fprintf('FOV (h, v, d): %.1f %.1f %.1f\n',thisR.get('hfov'), thisR.get('vfov'), thisR.get('fov'));

%% Changing the number of samples

% Initially 320 x 320
ss = thisR.get('spatial samples');

% Samples are (X,Y) in PBRT
thisR.set('spatial samples',round([ss(1),ss(2)/2]));

% Changing the number of samples also changes the sample spacing
thisR.summarize('camera');

thisR.set('spatial samples',ss);
thisR.summarize('camera');

% Changing the field of view, does not change the sample spacing on
% the film.  So, implicitly, it changes the film distance.
thisR.set('fov diagonal',5)
thisR.summarize('camera');

% This is what the image looks like
thisR.set('fov diagonal',45)
thisR.summarize('camera');
piWRS(thisR);

%% Doubling the original resolution

% 640 x 640
thisR.set('spatial samples',round(2*ss));

thisR.summarize('camera');
%{
Higher sampling density (sample spacing decreases). The film diagonal
is the same.  The field of view is the same.
%}
piWRS(thisR);

%%  An extreme case of generating a line sample 
%
% TG does this for speed, sometimes, say in calculating an edge spread
%

% This is a problem.  I do not understand why we are seeing the whole
% chess set.  We should only be seeing a strip through the chess set.
thisR.set('spatial samples',round([ss(1),32]));
thisR.summarize('camera');
thisR.get('d fov')
thisR.set('d fov',20);
%{
The sample spacing is large because the diagonal is along the film line;
when the image was square the horizontal distance was smaller so the
sample spacing was smaller. The horizontal field of view is the same.
%}
piWRS(thisR);

rgb = imageSPD(p,[],0.5);

%%

