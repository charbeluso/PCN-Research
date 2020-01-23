% How to draw a dot grid

% Clear the workspace and the screen
sca;
close all;
clearvars;

% Default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Random number generator
rand('seed', sum(100 * clock));

% Select screen with highest id as Oculus output display:
screenNumber = max(Screen('Screens'));

% Define white and black
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window and color it black.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window in pixels.
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing (OpenGL function)
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% ----- Difference between 1 dot and multiple dots start here -----

% Use the meshgrid command to create our base dot coordinates. This will
% simply be a grid of equally spaced coordinates in the X and Y dimensions,
% centered on 0,0
dim = 10;
[x, y] = meshgrid(-dim:1:dim, -dim:1:dim);

% Here we scale the grid so that it is in pixel coordinates. We just scale
% it by the screen size so that it will fit. This is simply a
% multiplication. Notice the "." before the multiplicaiton sign. This
% allows us to multiply each number in the matrix by the scaling value.
pixelScale = screenYpixels / (dim * 2 + 2);
x = x .* pixelScale;
y = y .* pixelScale;

% Calculate the number of dots
numDots = numel(x);

% Make the matrix of positions for the dots. This need to be a two row
% vector. The top row will be the X coordinate of the dot and the bottom
% row the Y coordinate of the dot. Each column represents a single dot. 
dotPositionMatrix = [reshape(x, 1, numDots); reshape(y, 1, numDots)];

% We can define a center for the dot coordinates to be relative to. Here
% we set the centre to be the centre of the screen
dotCenter = [xCenter yCenter];

% Set the color of our dot to be random i.e. a random number between 0 and
% 1
dotColors = rand(3, numDots) .* white;

% Set the size of the dots randomly between 10 and 30 pixels
dotSizes = rand(1, numDots) .* 20 + 10;

% Draw all of our dots to the screen in a single line of code
Screen('DrawDots', window, dotPositionMatrix, dotSizes, dotColors, dotCenter, 2);


% ---------------------------------------


% Flip to the screen. This command basically draws all of our previous
% commands onto the screen. 
Screen('Flip', window);

% Now we have drawn to the screen we wait for a keyboard button press (any
% key) to terminate the demo.
KbStrokeWait;

% Clear the screen. "sca" is short hand for "Screen CloseAll".
sca;