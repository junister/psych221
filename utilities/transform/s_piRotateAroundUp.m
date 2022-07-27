%% Notes on rotating around the UP direction
%
% This could be generalized to rotate around any vector, not just up.

%% Rotate around the this direction
%{
U = thisR.get('up')';
U = U/norm(U);
F = thisR.get('from')';
T = thisR.get('to')';
%}

%% Or rotate around the From-To direction
% {
F = thisR.get('From')';
FT = thisR.get('fromto');

% Plane perpendicular to fromto, but through the origin
pFT = null(FT);

% Move the from position in the plane perpendicular to FT
dx = pFT*[0.5 0]';
F  = F + dx;

% Choose to rotate around the from to direction
U = FT;
T = thisR.get('to')';

%}

%% Find the plane perpendicular to U through the origin

% Force U to be a row vector
pU = null(U(:)');

%  Find the position of F in the coordinate frame defined by pU and U.
%  The third coordinate is the value along the Up direction.  We
%  want to preserve that.
basisU = [pU,U(:)];

% F = basisU*[uF];
% basisU is orthonormal
uF = basisU'*F;

% Rotate the plane in the first two coordinates
nAng = 20;
ruF = zeros(3,nAng);
for ii=1:nAng
    angDeg = ii*15;
    M = piRotate([0 0 angDeg]);
    ruF(:,ii) = (uF'*M)';
end


% Now back into the original scene coordinate frame
rF = basisU*ruF;

%% Have a look at the various vectors

ieNewGraphWin;
p = plot3(U(1),U(2),U(3),'ro',...
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
