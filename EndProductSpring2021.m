function EndProductSpring2021(doSeparateEyeRender, multiSample, deviceindex, checkerboard)
% This script derives from DrawDots3DDemo:
% History:
% 03/01/2009  mk 
% 4/29/2021 Charmaine Beluso 

% I used the teapot demo and stripped it so that there was
% no more teapot and the particles that were coming out of the spout
% were white. This allowed for the observation of 3D dots in space with
% continuous head tracking, zoom in/out function into and out of the cloud
% of dots, no borders (infinite space), and all in Stereoscopic mode.

% In this demo, you can choose to have the particles rotate around an axis
% and view the cloud of dots in motion. The cloud of dots is organized in a
% conelike shape so that you can view denser amount of dots vs spread out
% dots.

% Pressing the ESCape key ends the demo. 
% Holding down the left click button on the mouse while moving the mouse in 
% the demo will zoom in/out. Simply moving the mouse without pressing
% anything will move the cloud up/down/left/right.

%** This is a final draft (cleaner & more organized script) of the work 
% done Spring 2021. In DotCloudinVRPracticeFOV.m, I tried to implement
% the hand tracking feature by mapping the keyboard strokes to the 
% VR controllers, but this driver does not support controller capability
% yet. I also messed with the lighting, movement, and keyboard input.

%--------------------------------------------------------------------------

% GL data structure needed for all OpenGL demos:
global GL;
global OVR;

if nargin < 1 || isempty(doSeparateEyeRender)
  doSeparateEyeRender = [];
end

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
RestrictKeysForKbCheck(KbName('ESCAPE'));


try
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

    Screen('TextSize', win, 18);

    % Setup the OpenGL rendering context of the onscreen window for use by
    % OpenGL wrapper. After this command, all following OpenGL commands will
    % draw into the onscreen window 'win':
    Screen('BeginOpenGL', win);

    % Get the aspect ratio of the screen:
    ar=RectHeight(winRect) / RectWidth(winRect);

	% Set viewport properly:
	glViewport(0, 0, RectWidth(winRect), RectHeight(winRect));
	
    % Setup default drawing color to white (R,G,B)=(1,1,1). This color only
    % gets used when lighting is disabled - if you comment out the call to
    % glEnable(GL.LIGHTING). <- which is commented out
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

    % Does use occlusion testing via depth buffer, does use
    % lighting. Uses manual switching between 2D and 3D for higher efficiency.

    % Number of random dots, whose positions are computed in Matlab on CPU:
    ndots = 100;

    % Number of fountain particles whose positions are computed on the GPU:
    nparticles = 10000;

    % Diameter of particles in pixels:
    particleSize = 5;

    % 'StartPosition' is the 3D position where all particles originate.
    StartPosition = [0, 0, 0];

    % Lifetime for each simulated particle, is chosen so that there seems to be
    % an infinite stream of particles, although the same particles are recycled
    % over and over:
    particlelifetime = 2;

    % Amount of "flow": A value of 1 will create a continuous stream, whereas
    % smaller value create bursts of particles: (for some reason, this does
    % not work anymore/the particles do not flow)
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

    % Maximum speed for particles:
    maxspeed = 2;

    % Per-component speed: We select these to shape the fountain in our wanted
    % direction:
    vxmax = maxspeed;
    vymax = maxspeed;
    vzmax = 0.4 * maxspeed;

    % Assign random velocities in (vx,vy,vz) direction: Intervals chosen to
    % shape the beam.
    particlesxyzt(1,:) = RandLim([1, nparticles],    0.7, +vxmax);
    particlesxyzt(2,:) = RandLim([1, nparticles],    0.7, +vymax);
    particlesxyzt(3,:) = RandLim([1, nparticles], -vzmax, +vzmax);

    % The w-component (4th dimension) encodes the birthtime of the particle. We
    % assign random birthtimes within the possible particlelifetime to get a
    % nice continuous stream of particles. Well, kind of: The flowfactor
    % controls the "burstiness" of particle flow. A value of 1 will create a
    % continous stream, whereas smaller values will create bursts of particles,
    particlesxyzt(4,:) = RandLim([1, nparticles], 0.0, particlelifetime * 0.3);

    % Manually enable 3D mode:
    Screen('BeginOpenGL', win);
    
    % Predraw the particles. Here particlesxyzt does not encode position, but
    % speed -- this because our shader interprets positions as velocities!
    gld = glGenLists(1);
    glNewList(gld, GL.COMPILE);
    moglDrawDots3D(win, particlesxyzt, 5, [], [], 1);
    glEndList;

    % Enable lighting:
    % glEnable(GL.LIGHTING);

    % Enable proper occlusion handling via depth tests:
    glEnable(GL.DEPTH_TEST);

    % Set light position:
    % glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

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
        
%-------------------------------------------------------------------------
% Comment this out if you want to stop the spinning
% 
%       else
%         glRotated(10 * telapsed, 0, 1, 0);
%         glRotated(5  * telapsed, 1, 0, 0);
%-------------------------------------------------------------------------
      end
      
      % Compute simulation time for this draw cycle:
      telapsed = (vbl - tstart) * 1;

      moglDrawDots3D(win, particlesxyzt, 5, [], [], 1);

      % Manually disable 3D mode before switching to other eye or to flip:
      Screen('EndOpenGL', win);
        
      % Repeat for renderPass of other eye:
    end
    
    % Mark end of all graphics operation (until flip). This allows GPU to
    % optimize its operations:
    Screen('DrawingFinished', win, 2);

    % Stimulus ready. Show it on the HMD. We don't clear the color buffer here,
    % as this is done in the next iteration via glClear() call anyway:
    fcount = fcount + 1;
    [vbl, onset(fcount)] = Screen('Flip', win, [], 1);
    
    % Result of GPU time measurement expected?
    if gpumeasure
        % Retrieve results from GPU load measurement:
        % Need to poll, as this is asynchronous and non-blocking,
        % so may return a zero time value at first invocation(s),
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

    end
    

    KbReleaseWait;
    Screen('Flip', win);
    
    Priority(0);
    ShowCursor(screenid);

    % Done. Close screen and exit:
    sca;

catch
    sca;
    psychrethrow(psychlasterror);
end

