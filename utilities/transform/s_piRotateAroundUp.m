%% Notes on rotating around the UP direction
%
% This could be generalized to rotate around any vector, not just up.

%% Rotate around the this direction
% {
rotateAround = thisR.get('to')';
rotateAround = rotateAround/norm(rotateAround);

% Plane perpendicular to 'up', but through the origin
pRA = null(rotateAround(:)');

% Start a little displaced from F.
F = thisR.get('From')';
dx = pRA*[0.05 0]';
Fstart  = F + dx;

%}

%% Or rotate around the From-To direction
%{

% We will rotate around this direction.
rotateAround = thisR.get('fromto');
rotateAround = rotateAround/norm(rotateAround);

% Plane perpendicular to fromto, but through the origin
pRA = null(rotateAround(:)');

% Start a little displaced from F.
F = thisR.get('From')';
dx = pRA*[0.05 0]';
Fstart  = F + dx;

%}

%% Find the plane perpendicular to U through the origin

% Force rotateAround to be a row vector.  Find the plane, throught the
% origin, that is perpendicular to the around direction.
pAround = null(rotateAround(:)');

%  Find the position of F in the coordinate frame defined by pAround
%  and rotateAround. The third coordinate is the value along the
%  Around direction.  We want to preserve that value.
basisU = [pAround,rotateAround(:)];

% Get the starting point in the 'around frame' for us to rotate
% This means solving for Faround
%    F = basisU*[Faround];
% basisU is orthonormal
Faround = basisU'*Fstart;

% Rotate the Faround plane in the first two coordinates of the Around
% coordinate frame.  The third coordinate should be the same as the
% rotateAround's third coordinate
nAng = 20;
ruF = zeros(3,nAng);
for ii=1:nAng
    angDeg = ii*15;
    M = piRotate([0 0 angDeg]);
    ruF(:,ii) = (Faround'*M)';
end

%% Convert the rotated vectors back into the original coordinate frame.  
% 

% We find the position of the from in the around coordinate frame.
Forig = basisU'*thisR.get('from')';

% We shift the rotated vectors in the around frame by an amount that
% centers them on the location of the from in that frame.  The shift
% is entirely within the perpendicular plane (first two coordinates of
% From).
%
% Then we transform the shifted vector back into the original coordinate
% frame.
rF = basisU*(ruF + [Forig(1),Forig(2),0]');

%% Have a look at the various vectors

ieNewGraphWin;
T = thisR.get('to')';
F = thisR.get('from');

p = plot3(rotateAround(1),rotateAround(2),rotateAround(3),'ro',...
    F(1),F(2),F(3),'gs',...
    T(1),T(2),T(3),'kx', ...
    'MarkerSize',10);
grid on;
legend({'Up','From','To'});

hold on;
for ii=1:nAng
    plot3(rF(1,ii),rF(2,ii),rF(3,ii),'bo','MarkerSize',8);
end
axis equal

%% Rotate around to see the circle around the red (Up) point.
