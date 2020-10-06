
function VRDotSpiralCloud(doSeparateEyeRender, multiSample, stereoscopic, checkerboard, deviceindex)
% VRHMDDemo1 -- Show 3D stereo display via MOGL OpenGL on a VR headset.

% History:
% 10-Sep-2015  mk  Written. Derived from DrawDots3DDemo.m

% Clear the workspace
clearvars;
close all;
sca;

% GL data structure needed for all OpenGL demos:
global GL;

if nargin < 1 || isempty(doSeparateEyeRender)
  doSeparateEyeRender = [];
end

if nargin < 2 || isempty(multiSample)
  multiSample = 8;
end

if nargin < 3 || isempty(stereoscopic)
  stereoscopic = 0;
end

if nargin < 4 || isempty(checkerboard)
  checkerboard = 0;
end

if nargin < 5
  deviceindex = [];
end


% Default setup:
PsychDefaultSetup(2);

% Find the screen to use for display:
screenid = max(Screen('Screens'));

% Determine the values of white
white = WhiteIndex(screenid);

try
  % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the
  % mogl OpenGL for Matlab/Octave wrapper:
  InitializeMatlabOpenGL;

  % Setup the HMD and open and setup the onscreen window for VR display:
  PsychImaging('PrepareConfiguration');
  hmd = PsychVRHMD('AutoSetupHMD', 'Tracked3DVR', 'LowPersistence TimeWarp FastResponse DebugDisplay', [], [], deviceindex);
  if isempty(hmd)
    fprintf('No VR-HMD available, giving up!\n');
    return;
  end

  [win, winRect] = PsychImaging('OpenWindow', screenid, 0, [], [], [], [], multiSample);

  % Query infos about this HMD:
  hmdinfo = PsychVRHMD('GetInfo', hmd);

  % Did user leave the choice to us, if separate eye rendering passes
  % should be used?
  if isempty(doSeparateEyeRender)
    % Yes: Ask the driver if separate passes would be beneficial, and
    % use them if the driver claims it is good for us:
    doSeparateEyeRender = hmdinfo.separateEyePosesSupported;
  end

  if doSeparateEyeRender
    fprintf('Will use separate eye render passes for enhanced quality on this HMD.\n');
  else
    fprintf('Will not use separate eye render passes, because on this HMD they would not be beneficial for quality.\n');
  end

  % Textsize for text:
  Screen('TextSize', win, 18);

  % Setup the OpenGL rendering context of the onscreen window for use by
  % OpenGL wrapper. After this command, all following OpenGL commands will
  % draw into the onscreen window 'win':
  Screen('BeginOpenGL', win);

  % Set viewport properly:
  glViewport(0, 0, RectWidth(winRect), RectHeight(winRect));

  % Setup default drawing color to yellow (R,G,B)=(1,1,0). This color only
  % gets used when lighting is disabled - if you comment out the call to
  % glEnable(GL.LIGHTING).
  glColor3f(1,1,0);

  % Setup OpenGL local lighting model: The lighting model supported by
  % OpenGL is a local Phong model with Gouraud shading.

  % Enable the first local light source GL.LIGHT_0. Each OpenGL
  % implementation is guaranteed to support at least 8 light sources,
  % GL.LIGHT0, ..., GL.LIGHT7
  glEnable(GL.LIGHT0);

  % Enable alpha-blending for smooth dot drawing:
  glEnable(GL.BLEND);
  glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

  % Retrieve and set camera projection matrix for optimal rendering on the HMD:
  [projMatrix{1}, projMatrix{2}] = PsychVRHMD('GetStaticRenderParameters', hmd);

  % Setup modelview matrix: This defines the position, orientation and
  % looking direction of the virtual camera:
  glMatrixMode(GL.MODELVIEW);
  glLoadIdentity;

  % Set background clear color to 'black' (R,G,B,A)=(0,0,0,0):
  glClearColor(0,0,0,0);

  % Clear out the backbuffer: This also cleans the depth-buffer for
  % proper occlusion handling: You need to glClear the depth buffer whenever
  % you redraw your scene, e.g., in an animation loop. Otherwise occlusion
  % handling will screw up in funny ways...
  glClear;

  % Finish OpenGL rendering into PTB window. This will switch back to the
  % standard 2D drawing functions of Screen and will check for OpenGL errors.
  Screen('EndOpenGL', win);

  % ---------------------

  % Get the width and height of the window in pixels
  [screenXpix, screenYpix] = Screen('WindowSize', win);
  
  % Determine the center of the screen. We will need this later when we draw
  % our dots.
  [center(1), center(2)] = RectCenter(winRect);
  
  % We assume some screen dimensions here so that the stimulus will fit
  % nicely on the screen
  screenYcm = 30;
  screenXcm = 30 * (screenXpix / screenYpix);
  cmPerPix = screenXcm / screenXpix;
  pixPerCm = screenXpix / screenXcm;
  
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
  
  % -----------------


  % Manually enable 3D mode:
  Screen('BeginOpenGL', win);

  % Enable lighting:
  glEnable(GL.LIGHTING);

  % Enable proper occlusion handling via depth tests:
  glEnable(GL.DEPTH_TEST);

  % Manually disable 3D mode.
  Screen('EndOpenGL', win);

  if checkerboard
    % Apply regular checkerboard pattern as texture:
    bv = zeros(32);
    wv = ones(32);
    myimg = double(repmat([bv wv; wv bv],32,32) > 0.5);
    mytex = Screen('MakeTexture', win, myimg, [], 1);

    % Retrieve OpenGL handles to the PTB texture. These are needed to use the texture
    % from "normal" OpenGL code:
    [gltex, gltextarget] = Screen('GetOpenGLTexture', win, mytex);

    % Begin OpenGL rendering into onscreen window again:
    Screen('BeginOpenGL', win);

    % Enable texture mapping for this type of textures...
    glEnable(gltextarget);

    % Bind our texture, so it gets applied to all following objects:
    glBindTexture(gltextarget, gltex);

    % Textures color texel values shall modulate the color computed by lighting model:
    glTexEnvfv(GL.TEXTURE_ENV,GL.TEXTURE_ENV_MODE,GL.REPLACE);

    % Clamping behaviour shall be a cyclic repeat:
    glTexParameteri(gltextarget, GL.TEXTURE_WRAP_S, GL.REPEAT);
    glTexParameteri(gltextarget, GL.TEXTURE_WRAP_T, GL.REPEAT);

    % Enable mip-mapping and generate the mipmap pyramid:
    glTexParameteri(gltextarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
    glTexParameteri(gltextarget, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
    glGenerateMipmapEXT(GL.TEXTURE_2D);

    Screen('EndOpenGL', win);
  end

  telapsed = 0;
  fcount = 0;

  % Allocate for up to 1000 seconds at nominal HMD fps:
  fps = Screen('FrameRate', win);
  if fps == 0
    fps = 60;
  end
  gpudur = zeros(1, fps * 1000);
  onset = zeros(1, fps * 1000);

  % Make sure all keys are released:
  KbReleaseWait;

  Priority(MaxPriority(win));

  % Get duration of a single frame:
  ifi = Screen('GetFlipInterval', win);

  globalPos = [0, 0, 3];
  heading = 0;

  [xc, yc] = RectCenter(winRect);
  SetMouse(xc,yc, screenid);
  HideCursor(screenid);
  [xo, yo] = GetMouse(screenid);

  % Initial flip to sync us to VBL and get start timestamp:
  [vbl, onset] = Screen('Flip', win);
  tstart = vbl;

  % VR render loop: Runs until keypress:
  while ~KbCheck
    % Update global position (x,y,z) by mouse movement:
    [xm, ym, buttons] = GetMouse(screenid);
    
    % Calculate the X screen position of the dots (note we have to convert
    % from degrees to radians here.
    xpos = cos(angles .* (pi / 180)) * cylWidth.* pixPerCm;
    
    for eye = 0:stereoscopic
      Screen('SelectStereoDrawBuffer', win, eye);
    % Draw the dots. Here we set them to white, determine the point at
    % which the dots are drawn relative to, in this case our screen center.
    % And set anti-aliasing to 1. This gives use smooth dots. If you use 0
    % instead you will get squares. And if you use 2 you will get nicer
    % anti-aliasing of the dots.
     Screen('DrawDots', win, [xpos; ypos], dotSizePixels, white, center, 1);

    end
    
    if ~any(buttons)
      % x-movement:
      globalPos(1) = globalPos(1) + 0.005 * (xm - xo);

      % y-movement:
      globalPos(2) = globalPos(2) + 0.005 * (yo - ym);
    else
      if buttons(1)
        % z-movement:
        globalPos(3) = globalPos(3) + 0.005 * (ym - yo);
      end

      if buttons(2)
        % Heading, ie. looking direction:
        heading = heading + 0.01 * (xm - xo);
      end
    end

    % Reposition mouse cursor for next drive cycle:
    SetMouse(xc,yc, screenid);
    [xo, yo] = GetMouse(screenid);

    % Compute a transformation matrix to globally position and orient the
    % observer in the scene. This allows mouse control of observer position
    % and heading on top of the head tracking:
    globalHeadPose = PsychGetPositionYawMatrix(globalPos, heading);

    % Track and predict head position and orientation, retrieve modelview
    % camera matrices for rendering of each eye. Apply some global transformation
    % to returned camera matrices. In this case a translation + rotation, as defined
    % by the PsychGetPositionYawMatrix() helper function:
    state = PsychVRHMD('PrepareRender', hmd, globalHeadPose);

    % We render the scene separately for each eye:
    for renderPass = 0:1
      % doSeparateEyeRender = 1 uses a method which may give slightly better
      % quality for fast head movements results on some manufacturers HMDs.
      % However, this comes at a small additional performance cost, so should
      % be avoided on HMDs where we know it won't help. See above on how one
      % can find out automatically if this will help or not, ie. how the value
      % of doSeparateEyeRender can be determined automatically.
      if doSeparateEyeRender
        % Query which eye to render in this renderpass, and query its
        % eyePose vector for the predicted eye position to use for the virtual
        % camera rendering that eyes view. The returned pose vector actually
        % describes tracked head pose, ie. HMD position and orientation in space.
        eye = PsychVRHMD('GetEyePose', hmd, renderPass, globalHeadPose);

        % Select 'eyeIndex' to render (left- or right-eye):
        Screen('SelectStereoDrawbuffer', win, eye.eyeIndex);

        % Extract modelView matrix for this eye:
        modelView = eye.modelView;
      else
        % Selected 'view' to render (left- or right-eye) equals the renderPass,
        % as order of rendering does not matter in this mode:
        Screen('SelectStereoDrawbuffer', win, renderPass);

        % Extract modelView matrix for this renderPass's eye:
        modelView = state.modelView{renderPass + 1};
      end

      % Manually reenable 3D mode in preparation of eye draw cycle:
      Screen('BeginOpenGL', win);

      % Set per-eye projection matrix: This defines a perspective projection,
      % corresponding to the model of a pin-hole camera - which is a good
      % approximation of the human eye and of standard real world cameras --
      % well, the best aproximation one can do with 2 lines of code ;-)
      glMatrixMode(GL.PROJECTION);
      glLoadMatrixd(projMatrix{renderPass+1});

      % Setup camera position and orientation for this eyes view:
      glMatrixMode(GL.MODELVIEW);
      glLoadMatrixd(modelView);

      glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

      % Clear color and depths buffers:
      glClear;

      if checkerboard
        % Checkerboard to better visualize distortions:
        glBegin(GL.QUADS)
        glColor3f(1,1,1);
        glTexCoord2f(0,0);
        glVertex2f(-1,-1);
        glTexCoord2f(1,0);
        glVertex2f(1,-1);
        glTexCoord2f(1,1);
        glVertex2f(1,1);
        glTexCoord2f(0,1);
        glVertex2f(-1,1);
        glEnd;
      else
        % Bring a bit of extra spin into this :-)
        glRotated(10 * telapsed, 0, 1, 0);
        glRotated(5  * telapsed, 1, 0, 0);
      end
      
      % Compute simulation time for this draw cycle:
      telapsed = (vbl - tstart) * 1;

      % Manually disable 3D mode before switching to other eye or to flip:
      Screen('EndOpenGL', win);

      % Repeat for renderPass of other eye:
    end

    % Head position tracked?
    if ~bitand(state.tracked, 2) && ~checkerboard
      % Nope, user out of cameras view frustum. Tell it like it is:
      DrawFormattedText(win, 'Vision based tracking lost\nGet back into the cameras field of view!', 'center', 'center', [1 0 0]);
    end

    % Stimulus ready. Show it on the HMD. We don't clear the color buffer here,
    % as this is done in the next iteration via glClear() call anyway:
    fcount = fcount + 1;
    [vbl, onset(fcount)] = Screen('Flip', win, [], 1);
    
    % Increment the angle of the dots by one degree per frame
    angles = angles + 1;

    % Next frame ...
  end

  % Cleanup:
  Priority(0);
  ShowCursor(screenid);
  sca;

catch
  sca;
  psychrethrow(psychlasterror);
end
