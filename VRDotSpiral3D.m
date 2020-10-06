function VRHMDDemo(stereoscopic, checkerboard, deviceindex)

% Clear the workspace
clearvars;
close all;
sca;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

%------------
if nargin < 1 || isempty(stereoscopic)
  stereoscopic = 0;
end

if nargin < 2 || isempty(checkerboard)
  checkerboard = 0;
end

if nargin < 3
  deviceindex = [];
end
%-------------

% Skip sync tests for this demo in case people are using a defective
% system. This is for demo purposes only.
Screen('Preference', 'SkipSyncTests', 2);

%--------------------------------------------------------------------------
%                       Screen initialisation
%--------------------------------------------------------------------------

% Find the screen to use for displaying the stimuli. By using "max" this
% will display on an external monitor if one is connected.
screenid = max(Screen('Screens'));

%---------------
% Open our fullscreen onscreen window with black background clear color:
PsychImaging('PrepareConfiguration');
if ~stereoscopic
  % Setup the HMD to act as a regular "monoscopic" display monitor
  % by displaying the same image to both eyes:
  PsychVRHMD('AutoSetupHMD', 'Monoscopic', 'LowPersistence FastResponse DebugDisplay', [], [], deviceindex);
else
  % Setup for stereoscopic presentation:
  PsychVRHMD('AutoSetupHMD', 'Stereoscopic', 'LowPersistence FastResponse', [], [], deviceindex);
end
%---------------

% Determine the values of black and white
black = BlackIndex(screenid);
white = WhiteIndex(screenid);

% Set up our screen
[window, windowRect] = PsychImaging('OpenWindow', screenid, black, [], 32, 2);

% Get the width and height of the window in pixels
[screenXpix, screenYpix] = Screen('WindowSize', window);

% Determine the center of the screen. We will need this later when we draw
% our dots.
[center(1), center(2)] = RectCenter(windowRect);

% We assume some screen dimensions here so that the stimulus will fit
% nicely on the screen
screenYcm = 30;
screenXcm = 30 * (screenXpix / screenYpix);
cmPerPix = screenXcm / screenXpix;
pixPerCm = screenXpix / screenXcm;

% Set the blend function so that we get nice antialised edges to the dots
% defining our cyliner
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


%--------------------------------------------------------------------------
%                   Stimulus information
%--------------------------------------------------------------------------

% Cylinder height, width and radius
cylHeight = 7;
cylWidth = 4;
cylRadius = cylWidth / 2;

% Numer of dots to place over the surface of the cylinder
numDots = 250;

% Dot track centres over the height of the cylinder
ypos = (rand(1, numDots) .* 2 - 1) .* cylHeight .* pixPerCm;

% Randomly assign the dots angles. This determines their X position on the
% screen. We are using ortographic projection, so the dots do not have a Z
% position.
angles = rand(1, numDots) .* 360;

% Set the dot size in pixels
dotSizePixels = 7;


%--------------------------------------------------------------------------
%                           Drawing Loop
%--------------------------------------------------------------------------


%----------------
if checkerboard
  % Apply regular checkerboard pattern as texture:
  bv = zeros(32);
  wv = ones(32);
  myimg = double(repmat([bv wv; wv bv],32,32) > 0.5);
  mytex = Screen('MakeTexture', window, myimg, [], 1);
end

% Render one view for each eye in stereoscopic mode:
vbl = [];
%-----------------


% Stimulus drawing loop (exits when any button is pressed)
while ~KbCheck

    % Calculate the X screen position of the dots (note we have to convert
    % from degrees to radians here.
    xpos = cos(angles .* (pi / 180)) * cylWidth.* pixPerCm;

    for eye = 0:stereoscopic
      Screen('SelectStereoDrawBuffer', window, eye);
    % Draw the dots. Here we set them to white, determine the point at
    % which the dots are drawn relative to, in this case our screen center.
    % And set anti-aliasing to 1. This gives use smooth dots. If you use 0
    % instead you will get squares. And if you use 2 you will get nicer
    % anti-aliasing of the dots.
     Screen('DrawDots', window, [xpos; ypos], dotSizePixels, white, center, 1);

    end
    vbl(end+1) = Screen('Flip', window);

    % Increment the angle of the dots by one degree per frame
    angles = angles + 1;

end

% Clean up and leave the building
sca;

close all;
plot(1000 * diff(vbl));

clear all;

%Published with MATLAB® R2016a