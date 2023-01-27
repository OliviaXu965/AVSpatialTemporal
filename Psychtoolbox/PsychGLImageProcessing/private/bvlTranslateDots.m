function newDots = bvlTranslateDots(dots, strDir, delta)
% newDots = bvlTranslateDots(dots, strDir, delta)
%
% Translate dots in the given direction by the specified amount.
%
% dots      - [Nx2] array of dots to be translated.  First column is the x
%           coordinate, Second Column the y coordinate.
%           [x1 y1; x2 y2; .... xN yN];
%
% strDir    - string specifing the direction
%               'left', 'right', 'up', 'down'
%
% delta     - amount to translate
%
% newDots - [Nx2] translated array
%
% NOTE:  Origin is at top-left of screen.


% This was designed to be used with the Spatial Calibrate code in the UC
% Berkeley Bankslab.  Created a series of transformation functions so we
% can update the transforms in one location instead of scattered throughout
% several .m files or even throughout one giant file as was the case.
%
% This code was added when switching to Psychtoolbox 3.x.  In updated the
% code, switch to OpenGL screen space with origin at top-left.  Several
% places in the calibrate code used lower-left.  This created a lot of
% problems with the mouse input.
%
% Created: 2007-05-14 - cburns.

if nargin < 3
    disp('Usage:  newDots = bvlTranslateDots(dots, dir, delta);');
    return;
end

newDots = dots;

% Don't do anything if the dots array is empty.
% Sometimes this happens when people are selecting dots.  Shouldn't crash
% or anything, just move on.
if isempty(dots)
    return
end

if strcmp(strDir, 'left')
    newDots(:,1) = dots(:,1) - delta;
elseif strcmp(strDir, 'right')
    newDots(:,1) = dots(:,1) + delta;
elseif strcmp(strDir, 'up')
    newDots(:,2) = dots(:,2) - delta;
elseif strcmp(strDir, 'down')
    newDots(:,2) = dots(:,2) + delta;
else
    fprintf('Error::bvlTranslateDots, unknown direction: %s\n', strDir);
end
