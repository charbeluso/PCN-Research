% Clear the workspace and the screen
sca;
close all;
clearvars;

% Default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Select screen with highest id as Oculus output display:
screenNumber = max(Screen('Screens'));

white = WhiteIndex(screenNumber);

% Open our fullscreen onscreen window with black background clear color:
% PsychImaging('PrepareConfiguration');

% Open an on screen window using PsychImaging and color it white.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);


% ------------------------------------

% [win, rect] = PsychImaging('OpenWindow', screenNumber);





% This function call will give use the same information as contained in
% "windowRect"
rect = Screen('Rect', window);

% Get the size of the on screen window in pixels, these are the last two
% numbers in "windowRect" and "rect"
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels.
% xCenter = screenXpixels / 2
% yCenter = screenYpixels / 2
[xCenter, yCenter] = RectCenter(windowRect);

% Query the inter-frame-interval. This refers to the minimum possible time
% between drawing to the screen.
% Get duration of a single frame:
ifi = Screen('GetFlipInterval', window);

% We can also determine the refresh rate of our screen. The
% relationship between the two is: ifi = 1 / hertz
hertz = FrameRate(window);

% Here we get the pixel size. This is not the physical size of the pixels
% but the color depth of the pixel in bits
pixelSize = Screen('PixelSize', window);

% Queries the display size in mm as reported by the operating system. Note
% that there are some complexities here. See Screen DisplaySize? for
% information. So always measure your screen size directly.
[width, height] = Screen('DisplaySize', screenNumber);



% ------------------------------------




% Now we have drawn to the screen we wait for a keyboard button press (any
% key) to terminate the demo.
KbStrokeWait;

% Clear the screen.
sca;