function pts = piRotateFrom(thisR,direction,varargin)
% Return a set of points that sample around the from direction
%
% Brief
%  Sample points in a circle around a direction vector centered at the
%  'from' location
%
% Synopsis
%    pts = = piRotateFrom(thisR,direction,varargin)
%
% Inputs
%   thisR     - Recipe
%   direction - vector direction we want to rotate around
%
% Optional key/val
%   n samples - Number of points around the circle
%   show      - Plot the 3D graph showing the sampled 'from' points
%   radius    - Circle radius of the sample points
%
% Output
%   pts - Sample points in 3-space
%
% Description
%   
% See also
%  s_piRotate4AroundUp - might get deprecated, but for now a tutorial
%

% Examples:
%{
direction = thisR.get('fromto');
n = 20;
pts = piRotateFrom(thisR, direction,'n samples',n, 'show',true);
%}
%{
direction = thisR.get('up');
n = 35;
pts = piRotateFrom(thisR, direction,'n samples',n, 'show',true);
%}
%{
direction = [0 0 1]
n = 4;
pts = piRotateFrom(thisR, direction,'n samples',n, 'radius',5,'show',true);
%}
%{
pts = piRotateFrom(thisR, direction,'n samples',n, 'radius',5);

%}
%% Parse parameters

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addRequired('direction',@isvector);
p.addParameter('nsamples',5,@isnumeric);
p.addParameter('radius',1,@isnumeric);
p.addParameter('show',false,@islogical);

p.parse(thisR,direction,varargin{:});
nSamples = p.Results.nsamples;
show     = p.Results.show;
radius   = p.Results.radius;

%% Circle in the z=0 plane

[x,y] = ieCirclePoints(2*pi/nSamples);

z = zeros(numel(x),1)';
C = radius * [x(:),y(:),z(:)]';

%{
ieNewGraphWin;
plot3(x,y,z,'o');
axis equal; grid on;
%}

% Make sure direction is a unit vector
direction = direction/norm(direction);

% Plane perpendicular to direction
pRA = null(direction(:)');
basisAround = [pRA,direction(:)];

% Find the coordinates in the Around frame
%
%   C = basisAround * Caround;
%
% These should be a circle perpendicular to the direction direction.
% I thought there should be a transpose here, but ...
Caround = basisAround * C;

%{
ieNewGraphWin;
plot3(Caround(1,:),Caround(2,:),Caround(3,:),'o')
hold on;
line([0 direction(1)],[0 direction(2)],[0 direction(3)],'Color','b');
axis equal; grid on;
%}

% Shift the center of the circle to be centered at the from position
pts = Caround + thisR.get('from')';

if show
    % Must be perpendicular to blue (the direction)
    ieNewGraphWin;
    plot3(pts(1,:),pts(2,:),pts(3,:),'o');  % The points 
    hold on;
    
    % The direction line
    line([0 direction(1)],[0 direction(2)],[0 direction(3)],'Color','b');
    hold on;
    
    % The from-to direction
    from = thisR.get('from');
    to = thisR.get('to');
    line([from(1),to(1)],[from(2),to(2)],[from(3),to(3)],'Color','k');

    axis equal; grid on;
end

end

%%