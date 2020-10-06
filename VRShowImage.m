
function VRHMDDemo(stereoscopic, deviceindex)
% Clear the workspace and the screen
sca;
close all;
clearvars;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

%------------
if nargin < 1 || isempty(stereoscopic)
  stereoscopic = 0;
end

if nargin < 3
  deviceindex = [];
end
%-------------

% Select screen with highest id as Oculus output display:
screenNumber = max(Screen('Screens'));

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

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


% ---------------- Image 1 - Colorful Bunnies ---------------------------
% Here we load in an image from file. This one is a image of rabbits that
% is included with PTB
theImageLocation = [PsychtoolboxRoot 'PsychDemos' filesep...
    'AlphaImageDemo' filesep 'konijntjes1024x768.jpg'];
theImage = imread(theImageLocation);

% Get the size of the image
[s1, s2, s3] = size(theImage);

% Here we check if the image is too big to fit on the screen and abort if
% it is. See ImageRescaleDemo to see how to rescale an image.
if s1 > screenYpixels || s2 > screenYpixels
    disp('ERROR! Image is too big to fit on the screen');
    sca;
    return;
end

% Make the image into a texture
imageTexture = Screen('MakeTexture', window, theImage);
% -----------------------------------------------------------------------

% ---------------- Image 2 - Gray Bunnies ---------------------------
% Here we load in an image from file. This one is a image of rabbits that
% is included with PTB
theImageLocation2 = [PsychtoolboxRoot 'PsychDemos' filesep...
    'konijntjes1024x768gray.jpg'];
theImage2 = imread(theImageLocation2);

% Get the size of the image
[p1, p2, p3] = size(theImage2);
   
if p1 > screenYpixels || p2 > screenYpixels
    disp('ERROR! Image is too big to fit on the screen');
    sca;
    return;
end

% Make the image into a texture
imageTexture2 = Screen('MakeTexture', window, theImage2);
% -----------------------------------------------------------------------

% Render one view for each eye in stereoscopic mode:
vbl = [];
while ~KbCheck  
   for eye = 0:stereoscopic
    Screen('SelectStereoDrawBuffer', window, eye);
    % Draw the image to the screen, unless otherwise specified PTB will draw
    % the texture full size in the center of the screen. We first draw the
    % image in its correct orientation.
    if eye == 0
          Screen('DrawTexture', window, imageTexture, [], [], 0);
    else
          Screen('DrawTexture', window, imageTexture2, [], [], 0);
    end
   end
   vbl(end+1) = Screen('Flip', window);
end

%-----------------
KbStrokeWait;
% Clear the screen
sca;
close all;
end