function DotCloudinVRPracticeFOV(doSeparateEyeRender, multiSample, deviceindex, checkerboard)
% DrawDots3DDemo -- Show fast drawing of 3D dots.
%
% Usage: DrawDots3DDemo([stereoMode=0][, multiSample=0]);
%
% This demo shows how to use the moglDrawDots3D() function to draw 3D dots
% in OpenGL 3D mode. The function is mostly equivalent to
% Screen('DrawDots') for drawing of 2D dots in regular 2D mode.

% The second subdemo shows how to use a GLSL vertex shader on modern GPU's
% to speed up complex drawing of complex 3D dot fields. It shows a nicely
% shaded, slowly rotating "Utah Teapot". Below the teapot is a primitive
% "sparkling fire" of 100 3D dots, which are lit by OpenGL and whose
% positions are computed in Matlab/Octave on the CPU. The teapot also emits
% a fountain of colorful particles from its nozzle. This fountain consists
% of 10000 particles, and the particle trajectories are computed on the GPU
% by use of a GLSL vertex shader. Please note that this subdemo may be
% pretty boring, not showing the magic fountain, if your GPU doesn't
% support shaders.

% Btw. if you are a proud owner of a good 3D stereo setup, or at least of
% some anaglyph glasses, you should try the stereo display option as well,
% e.g., stereoMode == 8 for red-blue anaglyphs.
%
% Pressing the ESCape key continues the demo and progresses to next
% subdemo. Mouse clicks will pause some demos, until another mouse click
% continues the demo.
%
% Optional parameter:
%
% 'stereoMode' if set to a non-zero value, will render at lest the 2nd demo
% in a binocular stereo presentation mode, using the method specified in
% the 'stereoMode' flag. See for example ImagingStereoDemo for available
% modes.
%
% 'multiSample' if set to a non-zero value will enable multi-sample
% anti-aliasing. This however usually doesn't give good results with
% smoothed 3D dots.
%

% History:
% 03/01/2009  mk  Written.

% GL data structure needed for all OpenGL demos:
global GL;
global OVR;

%------------
if nargin < 1 || isempty(doSeparateEyeRender)
  doSeparateEyeRender = [];
end
%-------------

if nargin < 2 || isempty(multiSample)
  multiSample = 8;
end

if nargin < 3
  deviceindex = [];
end

if nargin < 4  || isempty(checkerboard)
  checkerboard = 0;
end


% Find the screen to use for display:
screenid=max(Screen('Screens'));

% Is the script running in OpenGL Psychtoolbox? Abort, if not.
AssertOpenGL;

% Restrict KbCheck to checking of ESCAPE key:
KbName('UnifyKeynames');
%RestrictKeysForKbCheck(KbName('ALT'));
RestrictKeysForKbCheck(KbName('ESCAPE'));


try
    
    %---------------
    % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the
      % mogl OpenGL for Matlab/Octave wrapper:
      InitializeMatlabOpenGL;

    % Setup the HMD and open and setup the onscreen window for VR display:
      PsychImaging('PrepareConfiguration');
      hmd = PsychVRHMD('AutoSetupHMD', 'Tracked3DVR', 'LowPersistence TimeWarp FastResponse DebugDisplay', deviceindex);
      if isempty(hmd)
        fprintf('No VR-HMD available, giving up!\n');
        return;
      end

% ------------------------------------------------------------------------
% Hand Tracking Stuff 2/4/2021
% resource: http://psychtoolbox.org/docs/PsychVRHMD

      % Return a bitmask of all connected controllers: Can be the bitand
      % of the OVR.ControllerType_XXX flags described in ‘GetInputState’.
      % This does not detect if controllers are hot-plugged or unplugged after
      % the HMD was opened. Iow. only probed at ‘Open’.
      % 2/4/21
      PsychVRHMD('Controllers', hmd);
      
      % Get input state of controller ‘controllerType’ associated with HMD ‘hmd’.
       input = PsychVRHMD('GetInputState', hmd, OVR.ControllerType_Active);
       
       hmd.VRControllersSupported = 1;
       hmd.handTrackingSupported = 1;
       
       if isempty(OVR)
        % Define global OVR.XXX constants:
        OVR.ControllerType_LTouch = hex2dec('0001');
        OVR.ControllerType_RTouch = hex2dec('0002');
        OVR.ControllerType_Touch = OVR.ControllerType_LTouch + OVR.ControllerType_RTouch;
        OVR.ControllerType_Remote = hex2dec('0004');
        OVR.ControllerType_XBox = hex2dec('0010');
        OVR.ControllerType_Active = hex2dec('ffffffff');

        OVR.Button_A = 1 + log2(hex2dec('00000001'));
        OVR.Button_B = 1 + log2(hex2dec('00000002'));
        OVR.Button_RThumb = 1 + log2(hex2dec('00000004'));
        OVR.Button_RShoulder = 1 + log2(hex2dec('00000008'));
        OVR.Button_X = 1 + log2(hex2dec('00000100'));
        OVR.Button_Y = 1 + log2(hex2dec('00000200'));
        OVR.Button_LThumb = 1 + log2(hex2dec('00000400'));
        OVR.Button_LShoulder = 1 + log2(hex2dec('00000800'));
        OVR.Button_Up = 1 + log2(hex2dec('00010000'));
        OVR.Button_Down = 1 + log2(hex2dec('00020000'));
        OVR.Button_Left = 1 + log2(hex2dec('00040000'));
        OVR.Button_Right = 1 + log2(hex2dec('00080000'));
        OVR.Button_Enter = 1 + log2(hex2dec('00100000'));
        OVR.Button_Back = 1 + log2(hex2dec('00200000'));
        OVR.Button_VolUp = 1 + log2(hex2dec('00400000'));
        OVR.Button_VolDown = 1 + log2(hex2dec('00800000'));
        OVR.Button_Home = 1 + log2(hex2dec('01000000'));
        OVR.Button_Private = [OVR.Button_VolUp, OVR.Button_VolDown, OVR.Button_Home];
        OVR.Button_RMask = [OVR.Button_A, OVR.Button_B, OVR.Button_RThumb, OVR.Button_RShoulder];
        OVR.Button_LMask = [OVR.Button_X, OVR.Button_Y, OVR.Button_LThumb, OVR.Button_LShoulder, OVR.Button_Enter];

        OVR.Touch_A = OVR.Button_A;
        OVR.Touch_B = OVR.Button_B;
        OVR.Touch_RThumb = OVR.Button_RThumb;
        OVR.Touch_RThumbRest = 1 + log2(hex2dec('00000008'));
        OVR.Touch_RIndexTrigger = 1 + log2(hex2dec('00000010'));
        OVR.Touch_RButtonMask = [OVR.Touch_A, OVR.Touch_B, OVR.Touch_RThumb, OVR.Touch_RThumbRest, OVR.Touch_RIndexTrigger];
        OVR.Touch_X = OVR.Button_X;
        OVR.Touch_Y = OVR.Button_Y;
        OVR.Touch_LThumb = OVR.Button_LThumb;
        OVR.Touch_LThumbRest = 1 + log2(hex2dec('00000800'));
        OVR.Touch_LIndexTrigger = 1 + log2(hex2dec('00001000'));
        OVR.Touch_LButtonMask = [OVR.Touch_X, OVR.Touch_Y, OVR.Touch_LThumb, OVR.Touch_LThumbRest, OVR.Touch_LIndexTrigger];
        OVR.Touch_RIndexPointing = 1 + log2(hex2dec('00000020'));
        OVR.Touch_RThumbUp = 1 + log2(hex2dec('00000040'));
        OVR.Touch_LIndexPointing = 1 + log2(hex2dec('00002000'));
        OVR.Touch_LThumbUp = 1 + log2(hex2dec('00004000'));
        OVR.Touch_RPoseMask =  [OVR.Touch_RIndexPointing, OVR.Touch_RThumbUp];
        OVR.Touch_LPoseMask = [OVR.Touch_LIndexPointing, OVR.Touch_LThumbUp];

        OVR.TrackedDevice_HMD        = hex2dec('0001');
        OVR.TrackedDevice_LTouch     = hex2dec('0002');
        OVR.TrackedDevice_RTouch     = hex2dec('0004');
        OVR.TrackedDevice_Touch      = OVR.TrackedDevice_LTouch + OVR.TrackedDevice_RTouch;

        OVR.TrackedDevice_Object0    = hex2dec('0010');
        OVR.TrackedDevice_Object1    = hex2dec('0020');
        OVR.TrackedDevice_Object2    = hex2dec('0040');
        OVR.TrackedDevice_Object3    = hex2dec('0080');

        OVR.TrackedDevice_All        = hex2dec('FFFF');

        hmd.OVR = OVR;
        evalin('caller','global OVR');
      end
       

      % VRControllersSupported = 1;
        % VRControllersSupported = 1 if use of PsychVRHMD(‘GetInputState’) will provide input
        % from actual dedicated VR controllers. Value is 0 if
        % controllers are only emulated to some limited degree,
        % e.g., by abusing a regular keyboard as a button controller,
        % ie. mapping keyboard keys to OVR.Button_XXX buttons.
        
%       handTrackingSupported = 1 if PsychVRHMD(‘PrepareRender’) with reqmask +2 will provide
%     valid hand tracking info, 0 if this is not supported and will
%     just report fake values. A driver may report 1 here but still
%     don’t provide meaningful info at runtime, e.g., if required
%     tracking hardware is missing or gets disconnected. The flag
%     just aids extra performance optimizations in your code.

% ‘controllerType’ can be one of OVR.ControllerType_LTouch, OVR.ControllerType_RTouch,
% OVR.ControllerType_Touch, OVR.ControllerType_Remote, OVR.ControllerType_XBox, or
% OVR.ControllerType_Active for selecting whatever controller is currently active.
% ------------------------------------------------------------------------

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
    %---------------

    Screen('TextSize', win, 18);

    % Setup the OpenGL rendering context of the onscreen window for use by
    % OpenGL wrapper. After this command, all following OpenGL commands will
    % draw into the onscreen window 'win':
    Screen('BeginOpenGL', win);

    % Get the aspect ratio of the screen:
    ar=RectHeight(winRect) / RectWidth(winRect);

	% Set viewport properly:
	glViewport(0, 0, RectWidth(winRect), RectHeight(winRect));
	
    % Setup default drawing color to yellow (R,G,B)=(1,1,0). This color only
    % gets used when lighting is disabled - if you comment out the call to
    % glEnable(GL.LIGHTING).
    glColor3f(1,1,1);

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


 % Second version: Does use occlusion testing via depth buffer, does use
    % lighting. Uses manual switching between 2D and 3D for higher efficiency.
    % Creates a real 3D point-cloud around a teapot, as well as a vertex-shaded
    % fountain of particles that is emitted by the teapot:

    % Number of random dots, whose positions are computed in Matlab on CPU:
    ndots = 100;

    % Number of fountain particles whose positions are computed on the GPU:
    nparticles = 10000;

    % Diameter of particles in pixels:
    particleSize = 5;

    % 'StartPosition' is the 3D position where all particles originate. It is
    % faked to a position, so that the particles seem to originate from the
    % teapots "nozzle":
%     StartPosition = [1.44, 0.40, 0];
    StartPosition = [0, 3, 0];

    % Lifetime for each simulated particle, is chosen so that there seems to be
    % an infinite stream of particles, although the same particles are recycled
    % over and over:
    particlelifetime = 2;

    % Amount of "flow": A value of 1 will create a continuous stream, whereas
    % smaller value create bursts of particles:
    flowfactor = 1;
    
    % Load and setup the vertex shader for particle fountain animation:
      shaderpath = [PsychtoolboxRoot 'PsychDemos/OpenGL4MatlabDemos/GLSLDemoShaders/ParticleSimple'];
      glsl = LoadGLSLProgramFromFiles(shaderpath,1);

      % Bind shader so it can be setup:
      glUseProgram(glsl);

      % Assign static 3D startposition for fountain:
      glUniform3f(glGetUniformLocation(glsl, 'StartPosition'), StartPosition(1), StartPosition(2), StartPosition(3));

      % Assign lifetime:
      glUniform1f(glGetUniformLocation(glsl, 'LifeTime'), particlelifetime);

      % Assign simulated gravity constant 'g' for proper trajectory:
      glUniform1f(glGetUniformLocation(glsl, 'Acceleration'), 1.5);

      % Done with setup:
      glUseProgram(0);

    particlecolors = ones(3, nparticles) * 0.8;
%     particlecolors = rand(3, nparticles);

    % Maximum speed for particles:
    maxspeed = 2;

    % Per-component speed: We select these to shape the fountain in our wanted
    % direction:
    vxmax = maxspeed;
    vymax = maxspeed;
    vzmax = 0.4 * maxspeed;

    % Assign random velocities in (vx,vy,vz) direction: Intervals chosen to
    % shape the beam into something visually pleasing for a teapot:
    particlesxyzt(1,:) = RandLim([1, nparticles],    0.7, +vxmax);
    particlesxyzt(2,:) = RandLim([1, nparticles],    0.7, +vymax);
    particlesxyzt(3,:) = RandLim([1, nparticles], -vzmax, +vzmax);

    % The w-component (4th dimension) encodes the birthtime of the particle. We
    % assign random birthtimes within the possible particlelifetime to get a
    % nice continuous stream of particles. Well, kind of: The flowfactor
    % controls the "burstiness" of particle flow. A value of 1 will create a
    % continous stream, whereas smaller values will create bursts of particles,
    % as if the teapot is choking:
    particlesxyzt(4,:) = RandLim([1, nparticles], 0.0, particlelifetime * flowfactor);

    % Manually enable 3D mode:
    Screen('BeginOpenGL', win);
    
      % Predraw the particles. Here particlesxyzt does not encode position, but
  % speed -- this because our shader interprets positions as velocities!
  gld = glGenLists(1);
  glNewList(gld, GL.COMPILE);
%   moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);
  moglDrawDots3D(win, particlesxyzt, 5, [], [], 1);
  glEndList;

    % Enable lighting:
  %  glEnable(GL.LIGHTING);

    % Enable proper occlusion handling via depth tests:
    glEnable(GL.DEPTH_TEST);

    % Set light position:
%     glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

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

  globalPos = [0, 0, 2];
  heading = 0;

  [xc, yc] = RectCenter(winRect);
  SetMouse(xc,yc, screenid);
  HideCursor(screenid);
  [xo, yo] = GetMouse(screenid);

  % Initial flip to sync us to VBL and get start timestamp:
  [vbl, onset] = Screen('Flip', win);
  tstart = vbl;
  
  % We start with an empty dot array 'xyz' in first frame:
    xyz = [];

  % VR render loop: Runs until keypress:
  while ~KbCheck
    % Update global position (x,y,z) by mouse movement:
    [xm, ym, buttons] = GetMouse(screenid);
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
    
    % Track and predict head position and orientation, retrieve modelview
    % camera matrices for rendering of each eye. Apply some global transformation
    % to returned camera matrices. In this case a translation + rotation, as defined
    % by the PsychGetPositionYawMatrix() helper function:
    state = PsychVRHMD('PrepareRender', hmd, [], 2);
    reqmask = 2;
    
% ------------------------------------------------------------------------
% Hand Tracking Stuff 2/24/2021
% resource: http://psychtoolbox.org/docs/PsychVRHMD

    state.handStatus(1) = 3;
    state.handStatus(2) = 3;
    % Want matrices with tracked position and orientation of touch controllers ~ users hands?
    
  if bitand(reqmask, 2)
    % Yes: We can't do this on the legacy 0.5 SDK, so fake stuff:

    for i=1:2
      % state.handStatus(i) = 0;

      % Bonus feature: HandPoses as 7 component translation + orientation quaternion vectors:
      % state.handPose{i} = [0, 0, 0, 0, 0, 0, 1];

      % Convert hand pose vector to 4x4 OpenGL right handed reference frame matrix:
      % In our untracked case, simply an identity matrix:
      state.localHandPoseMatrix{1} = diag([1,1,1,1]);

      % Premultiply usercode provided global transformation matrix - here use as is:
      state.globalHandPoseMatrix{2} = diag([1 1 1 1]);
      
      % Compute inverse matrix, maybe useable for collision testing / virtual grasping of virtual objects:
      % Provides a transform that maps absolute geometry into geometry as "seen" from the pov of the hand.
      state.globalHandPoseInverseMatrix{1} = inv(state.globalHandPoseMatrix{i});
      state.globalHandPoseInverseMatrix{2} = inv(state.globalHandPoseMatrix{i});
    end
  end
  
  rc.Valid = 1;
  
  %http://psychtoolbox.org/docs/KbCheck
  [anykey, rc.Time, keyCodes] = KbCheck(-1);
  rc.Buttons = zeros(1, 32);
  
  %rc.Buttons(OVR.Button_A) = keyCode(KbName('ESCAPE'));
  %RestrictKeysForKbCheck(rc.Buttons(OVR.Button_A));
  
  if anykey
    %RestrictKeysForKbCheck(KbName('ALT'));
    %rc.Buttons(OVR.Button_A) = keyCodes(KbName('ESCAPE'));
    %RestrictKeysForKbCheck(rc.Buttons(OVR.Button_A));
    
    %rc.Buttons(OVR.Button_B) = keyCodes(KbName('b'));
    rc.Buttons(OVR.Button_X) = keyCodes(KbName('x'));
    rc.Buttons(OVR.Button_Y) = keyCodes(KbName('y'));
    rc.Buttons(OVR.Button_Back) = keyCodes(KbName('BackSpace'));
    rc.Buttons(OVR.Button_Enter) = any(keyCodes(KbName('Return')));
    rc.Buttons(OVR.Button_Right) = keyCodes(KbName('RightArrow'));
    rc.Buttons(OVR.Button_Left) = keyCodes(KbName('LeftArrow'));
    rc.Buttons(OVR.Button_Up) = keyCodes(KbName('UpArrow'));
    rc.Buttons(OVR.Button_Down) = keyCodes(KbName('DownArrow'));
    rc.Buttons(OVR.Button_VolUp) = keyCodes(KbName('F12'));
    rc.Buttons(OVR.Button_VolDown) = keyCodes(KbName('F11'));
    rc.Buttons(OVR.Button_RShoulder) = keyCodes(KbName('RightShift'));
    rc.Buttons(OVR.Button_LShoulder) = keyCodes(KbName('LeftShift'));
    rc.Buttons(OVR.Button_Home) = keyCodes(KbName('Home'));
    rc.Buttons(OVR.Button_RThumb) = any(keyCodes(KbName({'RightControl', 'RightAlt'})));
    rc.Buttons(OVR.Button_LThumb) = any(keyCodes(KbName({'LeftControl', 'LeftAlt'})));
  end
  
% ------------------------------------------------------------------------

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
    gpumeasure = Screen('GetWindowInfo', win, 5);

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
        
        % Comment this out if you want to stop the spinning
     % else
        % Bring a bit of extra spin into this :-)
      %  glRotated(10 * telapsed, 0, 1, 0);
      %  glRotated(5  * telapsed, 1, 0, 0);
      end
      
      % Compute simulation time for this draw cycle:
      telapsed = (vbl - tstart) * 1;
      
% %       glutSolidTeapot(1.0);
%        glUseProgram(glsl);
%        glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);
%        glCallList(gld);
       moglDrawDots3D(win, particlesxyzt, 5, [], [], 1);

%        [x,y,z] = CreateUniformDotsIn3DFrustum(ndots, 25, 1/ar, 0.1, 100);
%        moglDrawDots3D(win, [x ; y; z], 10, [255 255 0 255], [0, 0, 10], 1, []);

%        moglDrawDots3D(win, xyz, 5, [], [], 1);
%        glUseProgram(0);
 
      % Manually disable 3D mode before switching to other eye or to flip:
      Screen('EndOpenGL', win);
        
      % Repeat for renderPass of other eye:
    end
    
    % Mark end of all graphics operation (until flip). This allows GPU to
    % optimize its operations:
    Screen('DrawingFinished', win, 2);

    % Create uniform random distribution of 3D dots inside a cube for next
    % frame. We do it here after the Screen('DrawingFinished') command, so
    % Matlab can compute this random stuff while the GPU is drawing the dot
    % clouds etc. --> Parallelization allows for potential speedup.
    xyz = [RandLim([1,ndots], -1, 1) ; RandLim([1,ndots], -1, -0.7) ; RandLim([1,ndots], -1, 1)];


     % Head position tracked?
    if ~bitand(state.tracked, 2) && ~checkerboard
      % Nope, user out of cameras view frustum. Tell it like it is:
      DrawFormattedText(win, 'Vision based tracking lost\nGet back into the cameras field of view!', 'center', 'center', [1 0 0]);
    end

    % Stimulus ready. Show it on the HMD. We don't clear the color buffer here,
    % as this is done in the next iteration via glClear() call anyway:
    fcount = fcount + 1;
    [vbl, onset(fcount)] = Screen('Flip', win, [], 1);
    
    % Result of GPU time measurement expected?
    if gpumeasure
        % Retrieve results from GPU load measurement:
        % Need to poll, as this is asynchronous and non-blocking,
        % so may return a zero time valu1e at first invocation(s),
        % depending on how deep the rendering pipeline is:
        while 1
            winfo = Screen('GetWindowInfo', win);
            if winfo.GPULastFrameRenderTime > 0
                break;
            end
        end

        % Store it:
        gpudur(fcount) = winfo.GPULastFrameRenderTime;
    end

    %**************************************************************************

    end

    Priority(0);
    ShowCursor(screenid);

    % Done. Close screen and exit:
    sca;

catch
    sca;
    psychrethrow(psychlasterror);
end

