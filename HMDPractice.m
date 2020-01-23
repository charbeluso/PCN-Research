% How to draw a dot grid

function VRHMDDemo1(doSeparateEyeRender, multiSample, checkerboard)

% Clear the workspace and the screen
sca;
close all;
clearvars;

%---------
global GL;

if nargin < 1 || isempty(doSeparateEyeRender)
  doSeparateEyeRender = [];
end

if nargin < 2 || isempty(multiSample)
  multiSample = 8;
end

if nargin < 4  || isempty(checkerboard)
  checkerboard = 0;
end
%----------




% Default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Random number generator
rand('seed', sum(100 * clock));

% Select screen with highest id as Oculus output display:
screenNumber = max(Screen('Screens'));


%----
try
  % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the
  % mogl OpenGL for Matlab/Octave wrapper:
  InitializeMatlabOpenGL;

  % Setup the HMD and open and setup the onscreen window for VR display:
  PsychImaging('PrepareConfiguration');
  hmd = PsychVRHMD('AutoSetupHMD', 'Tracked3DVR', 'LowPersistence TimeWarp FastResponse DebugDisplay', 0);
  if isempty(hmd)
    fprintf('No VR-HMD available, giving up!\n');
    return;
  end

  [window, winRect] = PsychImaging('OpenWindow', screenNumber, 0, [], [], [], [], multiSample);

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
  Screen('TextSize', window, 18);

  % Setup the OpenGL rendering context of the onscreen window for use by
  % OpenGL wrapper. After this command, all following OpenGL commands will
  % draw into the onscreen window 'win':
  Screen('BeginOpenGL', window);

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
  Screen('EndOpenGL', window);
  
  % Done with setup:
  glUseProgram(0);

   % Manually enable 3D mode:
  Screen('BeginOpenGL', window);

  % Predraw the particles. Here particlesxyzt does not encode position, but
  % speed -- this because our shader interprets positions as velocities!
  gld = glGenLists(1);
  glNewList(gld, GL.COMPILE);
  
  glEndList;

  % Enable lighting:
  glEnable(GL.LIGHTING);

  % Enable proper occlusion handling via depth tests:
  glEnable(GL.DEPTH_TEST);

  % Manually disable 3D mode.
  Screen('EndOpenGL', window);

  if checkerboard
    % Apply regular checkerboard pattern as texture:
    bv = zeros(32);
    wv = ones(32);
    myimg = double(repmat([bv wv; wv bv],32,32) > 0.5);
    mytex = Screen('MakeTexture', window, myimg, [], 1);
    
     % Retrieve OpenGL handles to the PTB texture. These are needed to use the texture
    % from "normal" OpenGL code:
    [gltex, gltextarget] = Screen('GetOpenGLTexture', window, mytex);

    % Begin OpenGL rendering into onscreen window again:
    Screen('BeginOpenGL', window);

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

    Screen('EndOpenGL', window);
  end
  
  % Allocate for up to 1000 seconds at nominal HMD fps:
  fps = Screen('FrameRate', window);
  if fps == 0
    fps = 60;
  end
  gpudur = zeros(1, fps * 1000);
  onset = zeros(1, fps * 1000);

  % Make sure all keys are released:
  KbReleaseWait;

  Priority(MaxPriority(window));

  % Get duration of a single frame:
  ifi = Screen('GetFlipInterval', window);

  globalPos = [0, 0, 3];
  heading = 0;

  [xc, yc] = RectCenter(winRect);
  SetMouse(xc,yc, screenNumber);
  HideCursor(screenNumber);
  [xo, yo] = GetMouse(screenNumber);

  % Initial flip to sync us to VBL and get start timestamp:
  [vbl, onset] = Screen('Flip', window);
  tstart = vbl;
  
   % VR render loop: Runs until keypress:
  while ~KbCheck
    % Update global position (x,y,z) by mouse movement:
    [xm, ym, buttons] = GetMouse(screenNumber);
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
    SetMouse(xc,yc, screenNumber);
    [xo, yo] = GetMouse(screenNumber);

    % Compute a transformation matrix to globally position and orient the
    % observer in the scene. This allows mouse control of observer position
    % and heading on top of the head tracking:
    globalHeadPose = PsychGetPositionYawMatrix(globalPos, heading);

    % Track and predict head position and orientation, retrieve modelview
    % camera matrices for rendering of each eye. Apply some global transformation
    % to returned camera matrices. In this case a translation + rotation, as defined
    % by the PsychGetPositionYawMatrix() helper function:
    state = PsychVRHMD('PrepareRender', hmd, globalHeadPose);

    % Start rendertime measurement on GPU: 'gpumeasure' will be 1 if
    % this is supported by the current GPU + driver combo:
    gpumeasure = Screen('GetWindowInfo', window, 5);

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
        Screen('SelectStereoDrawbuffer', window, eye.eyeIndex);

        % Extract modelView matrix for this eye:
        modelView = eye.modelView;
      else
        % Selected 'view' to render (left- or right-eye) equals the renderPass,
        % as order of rendering does not matter in this mode:
        Screen('SelectStereoDrawbuffer', window, renderPass);

        % Extract modelView matrix for this renderPass's eye:
        modelView = state.modelView{renderPass + 1};
      end

      % Manually reenable 3D mode in preparation of eye draw cycle:
      Screen('BeginOpenGL', window);

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
      
      
    % ---------------------------------------------------------------------
      
      
    % Define white and black
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);

    % Open an on screen windowdow and color it black.
    [window, winRect] = PsychImaging('OpenWindow', screenNumber, black);

    % Get the size of the on screen window in pixels.
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);

    % Get the centre coordinate of the window in pixels
    [xCenter, yCenter] = RectCenter(winRect);

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
      
    % ---------------------------------------------------------------------
      
      
      
  
      % Manually disable 3D mode before switching to other eye or to flip:
      Screen('EndOpenGL', window);

      % Repeat for renderPass of other eye:
    end

    % Head position tracked?
    if ~bitand(state.tracked, 2) && ~checkerboard
      % Nope, user out of cameras view frustum. Tell it like it is:
      DrawFormattedText(window, 'Vision based tracking lost\nGet back into the cameras field of view!', 'center', 'center', [1 0 0]);
    end

    % Stimulus ready. Show it on the HMD. We don't clear the color buffer here,
    % as this is done in the next iteration via glClear() call anyway:
    fcount = fcount + 1;
    [vbl, onset(fcount)] = Screen('Flip', window, [], 1);

    % Result of GPU time measurement expected?
    if gpumeasure
        % Retrieve results from GPU load measurement:
        % Need to poll, as this is asynchronous and non-blocking,
        % so may return a zero time value at first invocation(s),
        % depending on how deep the rendering pipeline is:
        while 1
            winfo = Screen('GetWindowInfo', window);
            if winfo.GPULastFrameRenderTime > 0
                break;
            end
        end

        % Store it:
        gpudur(fcount) = winfo.GPULastFrameRenderTime;
    end

    % Next frame ...
  end

  % Cleanup:
  Priority(0);
  ShowCursor(screenNumber);
  sca;

end