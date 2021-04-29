% How to draw 1 dot

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

% Set the color of dot to red (RGB)
dotColor = [1 0 0];

% Determine a random X and Y position for our dot. NOTE: As dot position is
% randomised each time you run the script the output picture will show the
% dot in a different position. Similarly, when you run the script the
% position of the dot will be randomised each time. NOTE also, that if the
% dot is drawn at the edge of the screen some of it might not be visible.
dotXpos = rand * screenXpixels;
dotYpos = rand * screenYpixels;

% Dot size in pixels
dotSizePix = 20;

% Draw the dot to the screen.
Screen('DrawDots', window, [dotXpos dotYpos], dotSizePix, dotColor, [], 2);

% Flip to the screen. This command basically draws all of our previous
% commands onto the screen. 
Screen('Flip', window);

% Now we have drawn to the screen we wait for a keyboard button press (any
% key) to terminate the demo.
KbStrokeWait;

% Clear the screen. "sca" is short hand for "Screen CloseAll".
sca;