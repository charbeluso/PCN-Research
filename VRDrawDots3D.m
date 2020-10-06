
function VRDrawDots3D(stereoscopic, doSeparateEyeRender, stereoMode, multiSample)

% History:
% 10-Sep-2015  mk  Written. Derived from DrawDots3DDemo.m

% GL data structure needed for all OpenGL demos:
global GL;

if nargin < 1 || isempty(doSeparateEyeRender) || isempty(stereoMode) || isempty(stereoscopic)
  doSeparateEyeRender = [];
  stereoMode = [];
  stereoscopic = 1;
end

% if nargin < 1 || isempty(stereoMode)
%   stereoMode = [];
% endwww

if nargin < 2 || isempty(multiSample)
  multiSample = 8;
end

if isempty(stereoMode)
    stereoMode = 0;
end

if stereoMode
    stereoViews = 1;
else
    stereoViews = 0;
end

% Is the script running in OpenGL Psychtoolbox? Abort, if not.
AssertOpenGL;

% Restrict KbCheck to checking of ESCAPE key:
KbName('UnifyKeynames');
RestrictKeysForKbCheck(KbName('ESCAPE'));

% Default setup:
PsychDefaultSetup(2);

% Find the screen to use for display:
screenid = max(Screen('Screens'));


  % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the
  % mogl OpenGL for Matlab/Octave wrapper:
  InitializeMatlabOpenGL;

  % Setup the HMD and open and setup the onscreen window for VR display:
  PsychImaging('PrepareConfiguration');
  % hmd = PsychVRHMD('AutoSetupHMD', 'Tracked3DVR', 'LowPersistence TimeWarp FastResponse DebugDisplay', 0);
  hmd = PsychVRHMD('AutoSetupHMD', 'Stereoscopic', 'LowPersistence FastResponse DebugDisplay', [], [], 0);
  if isempty(hmd)
    fprintf('No VR-HMD available, giving up!\n');
    return;
  end

  [win, winRect] = PsychImaging('OpenWindow', screenid, 0, [], [], [], stereoMode, multiSample);

  if ismember(stereoMode, [6,7,8,9])
        SetAnaglyphStereoParameters('FullColorAnaglyphMode', win);
  end
    
  % Query infos about this HMD:
  hmdinfo = PsychVRHMD('GetInfo', hmd);

  % Did user leave the choice to us, if separate eye rendering passes
  % should be used?
%   if isempty(doSeparateEyeRender)
%     % Yes: Ask the driver if separate passes would be beneficial, and
%     % use them if the driver claims it is good for us:
%     doSeparateEyeRender = hmdinfo.separateEyePosesSupported;
%   end
% 
%   if doSeparateEyeRender
%     fprintf('Will use separate eye render passes for enhanced quality on this HMD.\n');
%   else
%     fprintf('Will not use separate eye render passes, because on this HMD they would not be beneficial for quality.\n');
%   end

  % Textsize for text:
  Screen('TextSize', win, 18);

  % Setup the OpenGL rendering context of the onscreen window for use by
  % OpenGL wrapper. After this command, all following OpenGL commands will
  % draw into the onscreen window 'win':
  Screen('BeginOpenGL', win);

  
  %-------------------
  % Get the aspect ratio of the screen:
  ar=RectHeight(winRect) / RectWidth(winRect);
  %-------------------
    
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
  
  % Field of view is 25 degrees from line of sight. Objects closer than
  % 0.1 distance units or farther away than 100 distance units get clipped
  % away, aspect ratio is adapted to the monitors aspect ratio:
  gluPerspective(25, 1/ar, 0.1, 100);

  % Setup modelview matrix: This defines the position, orientation and
  % looking direction of the virtual camera:
  glMatrixMode(GL.MODELVIEW);
  glLoadIdentity;

  % Our point lightsource is at position (x,y,z) == (1,2,3)...
  glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);
  
  % Cam is located at 3D position (3,3,5), points upright (0,1,0) and fixates
  % at the origin (0,0,0) of the worlds coordinate system:
  % The OpenGL coordinate system is a right-handed system as follows:
  % Default origin is in the center of the display.
  % Positive x-Axis points horizontally to the right.
  % Positive y-Axis points vertically upwards.
  % Positive z-Axis points to the observer, perpendicular to the display
  % screens surface.
  gluLookAt(0,0,10,0,0,0,0,1,0);
  
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
  
  %-------------------
  KbReleaseWait;
  DrawFormattedText(win, 'Now for a ugly demo of CPU based drawing of a uniform random dot field.\nPress ESCape key to continue and to finish a subdemo.', 'center', 'center', [255 255 0]);
  [vbl, onset] = Screen('Flip', win);
  KbStrokeWait;
  
  while ~KbCheck
  for eye = 0:stereoscopic
    Screen('SelectStereoDrawBuffer', win, eye);
   
      % Shows different text in each eye
      if eye == 1
          DrawFormattedText(win, sprintf('RIGHT%i', eye), 'center', 'center', [0 1 0]);
      else
          DrawFormattedText(win, sprintf('LEFT%i', eye), 'center', 'center', [0 1 0]);
      end
  end
  vbl(end+1) = Screen('Flip', win);
  end

  
  
%   Show rendered image at next vertical retrace:
  Screen('Flip', win);
  
  ndots = 1000;
  
  % First version: Does not use occlusion testing via depth buffer, does not
  % use lighting. Uses auto-switching between 2D and 3D for simpler code:
  
  % 3D Dots animation loop: Runs until keypress:
  while ~KbCheck
      DrawFormattedText(win, 'Now for a ugly demo of CPU based drawing of a uniform random dot field.\nPress ESCape key to continue and to finish a subdemo.', 'center', 'center', [255 255 0]);
      % Create random distribution of 3D dots inside our viewing frustum:
      [x,y,z] = CreateUniformDotsIn3DFrustum(ndots, 25, 1/ar, 0.1, 100);
      
      % Draw dots quickly: Common dotdiameter is 10 pixels, common color is
      % yellow. We move the center of the dots (aka position (0,0,0) to
      % position (0,0,10), so the above random transform applies properly:
      moglDrawDots3D(win, [x ; y; z], 10, [255 255 0 255], [0, 0, 10], 1, []);
      
      % Show'em:
      Screen('Flip', win, 0, 0);
      
      % A mouse button press will pause the animation:
      [x,y,buttons] = GetMouse;
      if any(buttons)
          % And wait for a single mouse click to continue:
          GetClicks;
      end
  end
  
  % Does this GPU support shaders?
  extensions = glGetString(GL.EXTENSIONS);
  if isempty(findstr(extensions, 'GL_ARB_shading_language')) || isempty(findstr(extensions, 'GL_ARB_shader_objects')) || isempty(findstr(extensions, 'GL_ARB_vertex_shader'))
      % Ok, no support for shading.
      shadingavail = 0;
  else
      % Use the shader stuff below this point...
      shadingavail = 1;
  end;
  
  KbReleaseWait;
  if shadingavail
      DrawFormattedText(win, 'Now for a beautiful demo of GPU based shading.\nPress ESCape key to continue and to finish a subdemo.', 'center', 'center', [255 255 0]);
  else
      DrawFormattedText(win, 'Now for another demo of CPU based drawing.\nPress ESCape key to continue and to finish a subdemo.\n\nUnfortunately your GPU does not support vertex shading\nso all following stuff will be pretty boring.', 'center', 'center', [255 255 0]);
  end
  
  Screen('Flip', win);
  KbStrokeWait;
  
  % Second version: Does use occlusion testing via depth buffer, does use
  % lighting. Uses manual switching between 2D and 3D for higher efficiency.
  % Creates a real 3D point-cloud around a teapot, as well as a vertex-shaded
  % fountain of particles that is emitted by the teapot:
  
  %---------------------
  
  % Number of random dots, whose positions are computed in Matlab on CPU:
  ndots = 100;

  % Number of fountain particles whose positions are computed on the GPU:
  nparticles = 10000;

  % Diameter of particles in pixels:
  particleSize = 5;

  % 'StartPosition' is the 3D position where all particles originate. It is
  % faked to a position, so that the particles seem to originate from the
  % teapots "nozzle":
  StartPosition = [1.44, 0.40, 0.0];

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

  % Assign random RGB colors to the particles: The shader will use these, but
  % also assign an alpha value that makes the particles "fade out" at the end
  % of there lifetime:
  particlecolors = rand(3, nparticles);
  
  % Maximum speed for particles:
  maxspeed = 1.25;

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

%   % Get duration of a single frame:
%   ifi = Screen('GetFlipInterval', win);
%   
%   % Initial flip to sync us to VBL and get start timestamp:
%   vbl = Screen('Flip', win);
%   tstart = vbl;
%   telapsed = 0;
  
  % Manually enable 3D mode:
  Screen('BeginOpenGL', win);

  % Predraw the particles. Here particlesxyzt does not encode position, but
  % speed -- this because our shader interprets positions as velocities!
  gld = glGenLists(1);
  glNewList(gld, GL.COMPILE);
  moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);
  glEndList;

  % Enable lighting:
  glEnable(GL.LIGHTING);

  % Enable proper occlusion handling via depth tests:
  glEnable(GL.DEPTH_TEST);

  % Manually disable 3D mode.
  Screen('EndOpenGL', win);

  
  
  
  
  
  
  
  
  
%    if checkerboard
%     % Apply regular checkerboard pattern as texture:
%     bv = zeros(32);
%     wv = ones(32);
%     myimg = double(repmat([bv wv; wv bv],32,32) > 0.5);
%     mytex = Screen('MakeTexture', win, myimg, [], 1);
% 
%     % Retrieve OpenGL handles to the PTB texture. These are needed to use the texture
%     % from "normal" OpenGL code:
%     [gltex, gltextarget] = Screen('GetOpenGLTexture', win, mytex);
% 
%     % Begin OpenGL rendering into onscreen window again:
%     Screen('BeginOpenGL', win);
% 
%     % Enable texture mapping for this type of textures...
%     glEnable(gltextarget);
% 
%     % Bind our texture, so it gets applied to all following objects:
%     glBindTexture(gltextarget, gltex);
% 
%     % Textures color texel values shall modulate the color computed by lighting model:
%     glTexEnvfv(GL.TEXTURE_ENV,GL.TEXTURE_ENV_MODE,GL.REPLACE);
% 
%     % Clamping behaviour shall be a cyclic repeat:
%     glTexParameteri(gltextarget, GL.TEXTURE_WRAP_S, GL.REPEAT);
%     glTexParameteri(gltextarget, GL.TEXTURE_WRAP_T, GL.REPEAT);
% 
%     % Enable mip-mapping and generate the mipmap pyramid:
%     glTexParameteri(gltextarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
%     glTexParameteri(gltextarget, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
%     glGenerateMipmapEXT(GL.TEXTURE_2D);
% 
%     Screen('EndOpenGL', win);
%   end

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

%       if checkerboard
%         % Checkerboard to better visualize distortions:
%         glBegin(GL.QUADS)
%         glColor3f(1,1,1);
%         glTexCoord2f(0,0);
%         glVertex2f(-1,-1);
%         glTexCoord2f(1,0);
%         glVertex2f(1,-1);
%         glTexCoord2f(1,1);
%         glVertex2f(1,1);
%         glTexCoord2f(0,1);
%         glVertex2f(-1,1);
%         glEnd;
%       else
%         % Bring a bit of extra spin into this :-)
%         glRotated(10 * telapsed, 0, 1, 0);
%         glRotated(5  * telapsed, 1, 0, 0);
%       end
      
      
      
      
      
      
      %----
      
      
      
      % We start with an empty dot array 'xyz' in first frame:
    xyz = [];

    % 3D Dots animation loop: Runs until keypress:
    while ~KbCheck
        % I a stereo display mode, we render the scene for both eyes:
        for view = 0:stereoViews
            % Select 'view' to render (left- or right-eye):
            Screen('SelectStereoDrawbuffer', win, view);

            % Manually reenable 3D mode in preparation of eye draw cycle:
            Screen('BeginOpenGL', win);

            % Setup camera for this eyes 'view':
            glMatrixMode(GL.MODELVIEW);
            glLoadIdentity;

            % This is a bit faked. For a proper solution see help for
            % moglStereoProjection:
            gluLookAt(-0.4 + view * 0.8 , 0, 10, 0, 0, 0, 0, 1, 0);

            % Clear color and depths buffers:
            glClear;

            % Bring a bit of extra spin into this :-)
            glRotated(10 * telapsed, 0, 1, 0);
            glRotated(5  * telapsed, 1, 0, 0);

            % Draw a solid teapot of size 1.0:
            glutSolidTeapot(1.0);

            % For drawing of dots, we need to respecify the light source position,
            % but this must not apply to other objects like the teapot. Therefore
            % we first backup the current lighting settings...
            glPushAttrib(GL.LIGHTING_BIT);

            % ... then set the new light source position ...
            glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

            % Draw dots of random dot cloud quickly: Common dotdiameter is 5
            % pixels, point smoothing is on, but this time we don't set a dotcolor
            % at all. This way the color can be determined by OpenGL's lighting
            % calculations:
            moglDrawDots3D(win, xyz, 5, [], [], 1);

            % Compute simulation time for this draw cycle:
            telapsed = vbl - tstart;

            if shadingavail
                % Draw the particle fountain. We use a vertex shader in the shader
                % program glsl to compute the physics:
                glUseProgram(glsl);

                % Assign updated simulation time to shader:
                glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);

                % Draw the particles. Here particlesxyzt does not encode position,
                % but speed vectors -- this because our shader interprets positions
                % as velocities!
                moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);

                % Done with shaded drawing:
                glUseProgram(0);
            end

            % ... restore old light settings from backup ...
            glPopAttrib;

            % Manually disable 3D mode before calling Screen('Flip')!
            Screen('EndOpenGL', win);

            % Repeat for other eyes view if in stereo presentation mode...
        end

        % Mark end of all graphics operation (until flip). This allows GPU to
        % optimize its operations:
        Screen('DrawingFinished', win, 2);

        % Create uniform random distribution of 3D dots inside a cube for next
        % frame. We do it here after the Screen('DrawingFinished') command, so
        % Matlab can compute this random stuff while the GPU is drawing the dot
        % clouds etc. --> Parallelization allows for potential speedup.
        xyz = [RandLim([1,ndots], -1, 1) ; RandLim([1,ndots], -1, -0.7) ; RandLim([1,ndots], -1, 1)];

        % Show'em: We don't clear the color buffer here, as this is done in
        % next iteration via glClear() call anyway:
        vbl = Screen('Flip', win, vbl + 0.5 * ifi, 2);

        % A mouse button press will pause the animation:
        [x,y,buttons] = GetMouse;
        if any(buttons)
            % Wait for a single mouse click to continue:
            GetClicks;
        end
    end

    % Now a benchmark run to test different strategies for their speed...

    KbReleaseWait;
    Screen('Flip', win);

    if shadingavail
        maxrendermode = 2;
    else
        maxrendermode = 0;
    end

    for rendermode=0:maxrendermode
        switch(rendermode)
            case 0,
                msgtxt = 'Testing now Matlab + CPU animation.';
            case 1,
                msgtxt = 'Testing now vertex shader GPU animation.';
            case 2
                msgtxt = 'Testing now optimized vertex shader GPU animation by use of display lists.';
        end

        DrawFormattedText(win, [msgtxt '\nMax test duration will be 20 seconds.\nPress ESCape key to continue and to finish a subdemo.'], 'center', 'center', [255 255 0]);
        Screen('Flip', win);
        KbStrokeWait;

        % Initial flip to sync us to VBL and get start timestamp:
        vbl = Screen('Flip', win);
        tstart = vbl;
        fc = 0;

        Screen('BeginOpenGL', win);
        glDisable(GL.LIGHTING);

        if rendermode == 2
            % Predraw the particles. Here particlesxyzt does not encode position, but
            % speed -- this because our shader interprets positions as velocities!
            gld = glGenLists(1);
            glNewList(gld, GL.COMPILE);
            moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, -StartPosition, 1);
            glEndList;
        end

        Screen('EndOpenGL', win);

        % For the fun of it, a little shoot-out between a purely Matlab + CPU based
        % solution, and two different GPU approaches:
        % 3D Dots animation loop: Runs until keypress or 20 seconds elapsed.
        while ~KbCheck && (vbl - tstart < 20)
            % Manually reenable 3D mode in preparation of eye draw cycle:
            Screen('BeginOpenGL', win);

            % Clear color and depths buffers:
            glClear;

            % Compute simulation time for this draw cycle:
            telapsed = vbl - tstart;

            if rendermode > 0
                % Draw the particle fountain. We use a vertex shader in the shader
                % program glsl to compute the physics:
                glUseProgram(glsl);

                % Assign updated simulation time to shader:
                glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);

                if rendermode == 1
                    % Draw the particles. Here particlesxyzt does not encode position, but
                    % speed -- this because our shader interprets positions as velocities!
                    moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, -StartPosition, 1);
                else
                    % Draw particles, but use display list instead of direct call
                    glCallList(gld);
                end

                % Done with shaded drawing:
                glUseProgram(0);
            else
                % Do it yourself in Matlab:
                t = max( (telapsed - particlesxyzt(4,:)) , repmat(0.0, 1, nparticles) );
                t = mod(t, particlelifetime);

                Acceleration = 1.5;
                vpositions(1:3,:) = (particlesxyzt(1:3,:) .* repmat(t, 3, 1));
                vpositions(2,:)   = vpositions(2,:) - (Acceleration * (t.^2));

                particlecolors(4,:) = 1.0 - (t / particlelifetime);

                moglDrawDots3D(win, vpositions, particleSize, particlecolors, [], 1);
            end

            % Manually disable 3D mode before calling Screen('Flip')!
            Screen('EndOpenGL', win);

            % Show'em: We don't clear the color buffer here, as this is done in
            % next iteration via glClear() call anyway. We swap asap, without sync
            % to VBL as this is a benchmark:
            Screen('Flip', win, [], 2, 2);

            % Need a fake vbl timestamp to keep simulation running:
            vbl = GetSecs;

            % Count of drawn frame:
            fc = fc + 1;
        end

        tend = Screen('Flip', win);
        avgfps = fc / (tend - tstart);

        switch(rendermode)
            case 0,
                msgtxt = 'Matlab + CPU';
            case 1,
                msgtxt = 'Shader + GPU';
            case 2
                msgtxt = 'Shader + GPU + VRAM Display lists';
        end

        fprintf('Average framerate FPS for rendermode %i [%s] is: %f Hz.\n', rendermode, msgtxt, avgfps);
        if rendermode == 2
            glDeleteLists(gld,1);
        end

        % Repeat benchmark for other renderModes:
    end

    % A last demo: Warp Drive!
    KbReleaseWait;

    % Respecify StartPosition for particle flow to "behind origin":
    StartPosition = [0, 0, -60];

    if shadingavail
        % Setup the vertex shader for particle fountain animation:

        % Bind shader so it can be setup:
        glUseProgram(glsl);

        % Assign static 3D startposition for fountain:
        glUniform3f(glGetUniformLocation(glsl, 'StartPosition'), StartPosition(1), StartPosition(2), StartPosition(3));

        % Assign lifetime: 10 x increased for starfield simulation...
        glUniform1f(glGetUniformLocation(glsl, 'LifeTime'), 10 * particlelifetime);
        particlesxyzt(4,:) = 10 * particlesxyzt(4,:);

        % Assign no simulated gravity, i.e., set to zero, so we don't get
        % gravity in space:
        glUniform1f(glGetUniformLocation(glsl, 'Acceleration'), 0.0);

        % Done with setup:
        glUseProgram(0);
    end

    % Reassign random velocities in (vx,vy,vz) direction: Intervals chosen to
    % shape the beam into something visually pleasing for a warp-flight:
    maxspeed = 1;
    particlesxyzt(1,:) = RandLim([1, nparticles],  -maxspeed, +maxspeed);
    particlesxyzt(2,:) = RandLim([1, nparticles],  -maxspeed, +maxspeed);
    particlesxyzt(3,:) = RandLim([1, nparticles],          0, 5 * maxspeed);
    particlesxyzt(3,:) = 5 * maxspeed;
    
    % Initial flip to sync us to VBL and get start timestamp:
    vbl = Screen('Flip', win);
    tstart = vbl;
    telapsed = 0;

    % Manually enable 3D mode:
    Screen('BeginOpenGL', win);

    % Enable lighting:
    glEnable(GL.LIGHTING);

    % Enable proper occlusion handling via depth tests:
    glEnable(GL.DEPTH_TEST);

    % Set light position:
    glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

    % Manually disable 3D mode.
    Screen('EndOpenGL', win);

    % 3D Dots animation loop: Runs until keypress:
    while ~KbCheck
        % I a stereo display mode, we render the scene for both eyes:
        for view = 0:stereoViews
            % Select 'view' to render (left- or right-eye):
            Screen('SelectStereoDrawbuffer', win, view);

            % Manually reenable 3D mode in preparation of eye draw cycle:
            Screen('BeginOpenGL', win);

            % Setup camera for this eyes 'view':
            glMatrixMode(GL.MODELVIEW);
            glLoadIdentity;

            % This is a bit faked. For a proper solution see help for
            % moglStereoProjection:
            gluLookAt(-0.4 + view * 0.8 , 0, 10, 0, 0, 0, 0, 1, 0);

            % Clear color and depths buffers:
            glClear;

            % Bring a bit of extra spin into this :-)
            glRotated(5 * telapsed, 0, 0, 1);

            % For drawing of dots, we need to respecify the light source position,
            % but this must not apply to other objects like the teapot. Therefore
            % we first backup the current lighting settings...
            glPushAttrib(GL.LIGHTING_BIT);

            % ... then set the new light source position ...
            glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);

            % Compute simulation time for this draw cycle:
            telapsed = vbl - tstart;

            if shadingavail
                % Draw the particle fountain. We use a vertex shader in the shader
                % program glsl to compute the physics:
                glUseProgram(glsl);

                % Assign updated simulation time to shader:
                glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);

                % Draw the particles. Here particlesxyzt does not encode position,
                % but speed vectors -- this because our shader interprets positions
                % as velocities!
                moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);

                % Done with shaded drawing:
                glUseProgram(0);
            end

            % ... restore old light settings from backup ...
            glPopAttrib;

            % Manually disable 3D mode before calling Screen('Flip')!
            Screen('EndOpenGL', win);

            % Repeat for other eyes view if in stereo presentation mode...
        end

        % Mark end of all graphics operation (until flip). This allows GPU to
        % optimize its operations:
        Screen('DrawingFinished', win, 2);

        % Show'em: We don't clear the color buffer here, as this is done in
        % next iteration via glClear() call anyway:
        vbl = Screen('Flip', win, vbl + 0.5 * ifi, 2);

        % A mouse button press will pause the animation:
        [x,y,buttons] = GetMouse;
        if any(buttons)
            % Wait for a single mouse click to continue:
            GetClicks;
        end
    end
    % Done. Close screen and exit:
    sca;
    

    % Reenable all keys for KbCheck:
    RestrictKeysForKbCheck([]);
    psychrethrow(psychlasterror);

end

return;

  
      
      
    %----
      
      
      
      
      
      
      
      
      
      
      

%       % Draw a solid teapot of size 1.0:
%       glutSolidTeapot(1);
% 
%       % Compute simulation time for this draw cycle:
%       telapsed = (vbl - tstart) * 1;
% 
%       if fountain
%         % Draw the particle fountain. We use a vertex shader in the shader
%         % program glsl to compute the physics:
%         glUseProgram(glsl);
% 
%         % Assign updated simulation time to shader:
%         glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);
% 
%         % Draw the particles: We have preencoded them into a OpenGL display list
%         % above for higher performance of drawing:
%         glCallList(gld);
% 
%         % Done with shaded drawing:
%         glUseProgram(0);
%       end
% 
%       % Manually disable 3D mode before switching to other eye or to flip:
%       Screen('EndOpenGL', win);
% 
%       % Repeat for renderPass of other eye:
%     end
% 
%     % Head position tracked?
%     if ~bitand(state.tracked, 2) && ~checkerboard
%       % Nope, user out of cameras view frustum. Tell it like it is:
%       DrawFormattedText(win, 'Vision based tracking lost\nGet back into the cameras field of view!', 'center', 'center', [1 0 0]);
%     end
% 
%     % Stimulus ready. Show it on the HMD. We don't clear the color buffer here,
%     % as this is done in the next iteration via glClear() call anyway:
%     fcount = fcount + 1;
%     [vbl, onset(fcount)] = Screen('Flip', win, [], 1);
% 
%     % Result of GPU time measurement expected?
%     if gpumeasure
%         % Retrieve results from GPU load measurement:
%         % Need to poll, as this is asynchronous and non-blocking,
%         % so may return a zero time value at first invocation(s),
%         % depending on how deep the rendering pipeline is:
%         while 1
%             winfo = Screen('GetWindowInfo', win);
%             if winfo.GPULastFrameRenderTime > 0
%                 break;
%             end
%         end
% 
%         % Store it:
%         gpudur(fcount) = winfo.GPULastFrameRenderTime;
%     end
% 
%     % Next frame ...
%   end
% 
%   % Cleanup:
%   Priority(0);
%   ShowCursor(screenid);
%   sca;
% 
%   sca;
%   psychrethrow(psychlasterror);
% end
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   
%   %**************************************************************************
%     
%   % We start with an empty dot array 'xyz' in first frame:
%     xyz = [];
% 
%     % 3D Dots animation loop: Runs until keypress:
%     while ~KbCheck
%         % I a stereo display mode, we render the scene for both eyes:
%         for view = 0:stereoViews
%             % Select 'view' to render (left- or right-eye):
%             Screen('SelectStereoDrawbuffer', win, view);
% 
%             % Manually reenable 3D mode in preparation of eye draw cycle:
%             Screen('BeginOpenGL', win);
% 
%             % Setup camera for this eyes 'view':
%             glMatrixMode(GL.MODELVIEW);
%             glLoadIdentity;
% 
%             % This is a bit faked. For a proper solution see help for
%             % moglStereoProjection:
%             gluLookAt(-0.4 + view * 0.8 , 0, 10, 0, 0, 0, 0, 1, 0);
% 
%             % Clear color and depths buffers:
%             glClear;
% 
%             % Bring a bit of extra spin into this :-)
%             glRotated(10 * telapsed, 0, 1, 0);
%             glRotated(5  * telapsed, 1, 0, 0);
% 
%             % Draw a solid teapot of size 1.0:
%             glutSolidTeapot(1.0);
% 
%             % For drawing of dots, we need to respecify the light source position,
%             % but this must not apply to other objects like the teapot. Therefore
%             % we first backup the current lighting settings...
%             glPushAttrib(GL.LIGHTING_BIT);
% 
%             % ... then set the new light source position ...
%             glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);
% 
%             % Draw dots of random dot cloud quickly: Common dotdiameter is 5
%             % pixels, point smoothing is on, but this time we don't set a dotcolor
%             % at all. This way the color can be determined by OpenGL's lighting
%             % calculations:
%             moglDrawDots3D(win, xyz, 5, [], [], 1);
% 
%             % Compute simulation time for this draw cycle:
%             telapsed = vbl - tstart;
% 
%             if shadingavail
%                 % Draw the particle fountain. We use a vertex shader in the shader
%                 % program glsl to compute the physics:
%                 glUseProgram(glsl);
% 
%                 % Assign updated simulation time to shader:
%                 glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);
% 
%                 % Draw the particles. Here particlesxyzt does not encode position,
%                 % but speed vectors -- this because our shader interprets positions
%                 % as velocities!
%                 moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);
% 
%                 % Done with shaded drawing:
%                 glUseProgram(0);
%             end
% 
%             % ... restore old light settings from backup ...
%             glPopAttrib;
% 
%             % Manually disable 3D mode before calling Screen('Flip')!
%             Screen('EndOpenGL', win);
% 
%             % Repeat for other eyes view if in stereo presentation mode...
%         end
% 
%         % Mark end of all graphics operation (until flip). This allows GPU to
%         % optimize its operations:
%         Screen('DrawingFinished', win, 2);
% 
%         % Create uniform random distribution of 3D dots inside a cube for next
%         % frame. We do it here after the Screen('DrawingFinished') command, so
%         % Matlab can compute this random stuff while the GPU is drawing the dot
%         % clouds etc. --> Parallelization allows for potential speedup.
%         xyz = [RandLim([1,ndots], -1, 1) ; RandLim([1,ndots], -1, -0.7) ; RandLim([1,ndots], -1, 1)];
% 
%         % Show'em: We don't clear the color buffer here, as this is done in
%         % next iteration via glClear() call anyway:
%         vbl = Screen('Flip', win, vbl + 0.5 * ifi, 2);
% 
%         % A mouse button press will pause the animation:
%         [x,y,buttons] = GetMouse;
%         if any(buttons)
%             % Wait for a single mouse click to continue:
%             GetClicks;
%         end
%     end
% 
%     % Now a benchmark run to test different strategies for their speed...
% 
%     KbReleaseWait;
%     Screen('Flip', win);
% 
%     if shadingavail
%         maxrendermode = 2;
%     else
%         maxrendermode = 0;
%     end
% 
%     for rendermode=0:maxrendermode
%         switch(rendermode)
%             case 0,
%                 msgtxt = 'Testing now Matlab + CPU animation.';
%             case 1,
%                 msgtxt = 'Testing now vertex shader GPU animation.';
%             case 2
%                 msgtxt = 'Testing now optimized vertex shader GPU animation by use of display lists.';
%         end
% 
%         DrawFormattedText(win, [msgtxt '\nMax test duration will be 20 seconds.\nPress ESCape key to continue and to finish a subdemo.'], 'center', 'center', [255 255 0]);
%         Screen('Flip', win);
%         KbStrokeWait;
% 
%         % Initial flip to sync us to VBL and get start timestamp:
%         vbl = Screen('Flip', win);
%         tstart = vbl;
%         fc = 0;
% 
%         Screen('BeginOpenGL', win);
%         glDisable(GL.LIGHTING);
% 
%         if rendermode == 2
%             % Predraw the particles. Here particlesxyzt does not encode position, but
%             % speed -- this because our shader interprets positions as velocities!
%             gld = glGenLists(1);
%             glNewList(gld, GL.COMPILE);
%             moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, -StartPosition, 1);
%             glEndList;
%         end
% 
%         Screen('EndOpenGL', win);
% 
%         % For the fun of it, a little shoot-out between a purely Matlab + CPU based
%         % solution, and two different GPU approaches:
%         % 3D Dots animation loop: Runs until keypress or 20 seconds elapsed.
%         while ~KbCheck && (vbl - tstart < 20)
%             % Manually reenable 3D mode in preparation of eye draw cycle:
%             Screen('BeginOpenGL', win);
% 
%             % Clear color and depths buffers:
%             glClear;
% 
%             % Compute simulation time for this draw cycle:
%             telapsed = vbl - tstart;
% 
%             if rendermode > 0
%                 % Draw the particle fountain. We use a vertex shader in the shader
%                 % program glsl to compute the physics:
%                 glUseProgram(glsl);
% 
%                 % Assign updated simulation time to shader:
%                 glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);
% 
%                 if rendermode == 1
%                     % Draw the particles. Here particlesxyzt does not encode position, but
%                     % speed -- this because our shader interprets positions as velocities!
%                     moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, -StartPosition, 1);
%                 else
%                     % Draw particles, but use display list instead of direct call
%                     glCallList(gld);
%                 end
% 
%                 % Done with shaded drawing:
%                 glUseProgram(0);
%             else
%                 % Do it yourself in Matlab:
%                 t = max( (telapsed - particlesxyzt(4,:)) , repmat(0.0, 1, nparticles) );
%                 t = mod(t, particlelifetime);
% 
%                 Acceleration = 1.5;
%                 vpositions(1:3,:) = (particlesxyzt(1:3,:) .* repmat(t, 3, 1));
%                 vpositions(2,:)   = vpositions(2,:) - (Acceleration * (t.^2));
% 
%                 particlecolors(4,:) = 1.0 - (t / particlelifetime);
% 
%                 moglDrawDots3D(win, vpositions, particleSize, particlecolors, [], 1);
%             end
% 
%             % Manually disable 3D mode before calling Screen('Flip')!
%             Screen('EndOpenGL', win);
% 
%             % Show'em: We don't clear the color buffer here, as this is done in
%             % next iteration via glClear() call anyway. We swap asap, without sync
%             % to VBL as this is a benchmark:
%             Screen('Flip', win, [], 2, 2);
% 
%             % Need a fake vbl timestamp to keep simulation running:
%             vbl = GetSecs;
% 
%             % Count of drawn frame:
%             fc = fc + 1;
%         end
% 
%         tend = Screen('Flip', win);
%         avgfps = fc / (tend - tstart);
% 
%         switch(rendermode)
%             case 0,
%                 msgtxt = 'Matlab + CPU';
%             case 1,
%                 msgtxt = 'Shader + GPU';
%             case 2
%                 msgtxt = 'Shader + GPU + VRAM Display lists';
%         end
% 
%         fprintf('Average framerate FPS for rendermode %i [%s] is: %f Hz.\n', rendermode, msgtxt, avgfps);
%         if rendermode == 2
%             glDeleteLists(gld,1);
%         end
% 
%         % Repeat benchmark for other renderModes:
%     end
% 
%     % A last demo: Warp Drive!
%     KbReleaseWait;
% 
%     % Respecify StartPosition for particle flow to "behind origin":
%     StartPosition = [0, 0, -60];
% 
%     if shadingavail
%         % Setup the vertex shader for particle fountain animation:
% 
%         % Bind shader so it can be setup:
%         glUseProgram(glsl);
% 
%         % Assign static 3D startposition for fountain:
%         glUniform3f(glGetUniformLocation(glsl, 'StartPosition'), StartPosition(1), StartPosition(2), StartPosition(3));
% 
%         % Assign lifetime: 10 x increased for starfield simulation...
%         glUniform1f(glGetUniformLocation(glsl, 'LifeTime'), 10 * particlelifetime);
%         particlesxyzt(4,:) = 10 * particlesxyzt(4,:);
% 
%         % Assign no simulated gravity, i.e., set to zero, so we don't get
%         % gravity in space:
%         glUniform1f(glGetUniformLocation(glsl, 'Acceleration'), 0.0);
% 
%         % Done with setup:
%         glUseProgram(0);
%     end
% 
%     % Reassign random velocities in (vx,vy,vz) direction: Intervals chosen to
%     % shape the beam into something visually pleasing for a warp-flight:
%     maxspeed = 1;
%     particlesxyzt(1,:) = RandLim([1, nparticles],  -maxspeed, +maxspeed);
%     particlesxyzt(2,:) = RandLim([1, nparticles],  -maxspeed, +maxspeed);
%     particlesxyzt(3,:) = RandLim([1, nparticles],          0, 5 * maxspeed);
%     particlesxyzt(3,:) = 5 * maxspeed;
%     
%     % Initial flip to sync us to VBL and get start timestamp:
%     vbl = Screen('Flip', win);
%     tstart = vbl;
%     telapsed = 0;
% 
%     % Manually enable 3D mode:
%     Screen('BeginOpenGL', win);
% 
%     % Enable lighting:
%     glEnable(GL.LIGHTING);
% 
%     % Enable proper occlusion handling via depth tests:
%     glEnable(GL.DEPTH_TEST);
% 
%     % Set light position:
%     glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);
% 
%     % Manually disable 3D mode.
%     Screen('EndOpenGL', win);
% 
%     % 3D Dots animation loop: Runs until keypress:
%     while ~KbCheck
%         % I a stereo display mode, we render the scene for both eyes:
%         for view = 0:stereoViews
%             % Select 'view' to render (left- or right-eye):
%             Screen('SelectStereoDrawbuffer', win, view);
% 
%             % Manually reenable 3D mode in preparation of eye draw cycle:
%             Screen('BeginOpenGL', win);
% 
%             % Setup camera for this eyes 'view':
%             glMatrixMode(GL.MODELVIEW);
%             glLoadIdentity;
% 
%             % This is a bit faked. For a proper solution see help for
%             % moglStereoProjection:
%             gluLookAt(-0.4 + view * 0.8 , 0, 10, 0, 0, 0, 0, 1, 0);
% 
%             % Clear color and depths buffers:
%             glClear;
% 
%             % Bring a bit of extra spin into this :-)
%             glRotated(5 * telapsed, 0, 0, 1);
% 
%             % For drawing of dots, we need to respecify the light source position,
%             % but this must not apply to other objects like the teapot. Therefore
%             % we first backup the current lighting settings...
%             glPushAttrib(GL.LIGHTING_BIT);
% 
%             % ... then set the new light source position ...
%             glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);
% 
%             % Compute simulation time for this draw cycle:
%             telapsed = vbl - tstart;
% 
%             if shadingavail
%                 % Draw the particle fountain. We use a vertex shader in the shader
%                 % program glsl to compute the physics:
%                 glUseProgram(glsl);
% 
%                 % Assign updated simulation time to shader:
%                 glUniform1f(glGetUniformLocation(glsl, 'Time'), telapsed);
% 
%                 % Draw the particles. Here particlesxyzt does not encode position,
%                 % but speed vectors -- this because our shader interprets positions
%                 % as velocities!
%                 moglDrawDots3D(win, particlesxyzt, particleSize, particlecolors, [], 1);
% 
%                 % Done with shaded drawing:
%                 glUseProgram(0);
%             end
% 
%             % ... restore old light settings from backup ...
%             glPopAttrib;
% 
%             % Manually disable 3D mode before calling Screen('Flip')!
%             Screen('EndOpenGL', win);
% 
%             % Repeat for other eyes view if in stereo presentation mode...
%         end
% 
%         % Mark end of all graphics operation (until flip). This allows GPU to
%         % optimize its operations:
%         Screen('DrawingFinished', win, 2);
% 
%         % Show'em: We don't clear the color buffer here, as this is done in
%         % next iteration via glClear() call anyway:
%         vbl = Screen('Flip', win, vbl + 0.5 * ifi, 2);
% 
%         % A mouse button press will pause the animation:
%         [x,y,buttons] = GetMouse;
%         if any(buttons)
%             % Wait for a single mouse click to continue:
%             GetClicks;
%         end
%     end
%     % Done. Close screen and exit:
%     sca;
% 
%     % Reenable all keys for KbCheck:
%     RestrictKeysForKbCheck([]);
% 
% catch
%     sca;
%     % Reenable all keys for KbCheck:
%     RestrictKeysForKbCheck([]);
%     psychrethrow(psychlasterror);
% end
% 
% return;
%   
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
%   if checkerboard
%     % Apply regular checkerboard pattern as texture:
%     bv = zeros(32);
%     wv = ones(32);
%     myimg = double(repmat([bv wv; wv bv],32,32) > 0.5);
%     mytex = Screen('MakeTexture', win, myimg, [], 1);
% 
%     % Retrieve OpenGL handles to the PTB texture. These are needed to use the texture
%     % from "normal" OpenGL code:
%     [gltex, gltextarget] = Screen('GetOpenGLTexture', win, mytex);
% 
%     % Begin OpenGL rendering into onscreen window again:
%     Screen('BeginOpenGL', win);
% 
%     % Enable texture mapping for this type of textures...
%     glEnable(gltextarget);
% 
%     % Bind our texture, so it gets applied to all following objects:
%     glBindTexture(gltextarget, gltex);
% 
%     % Textures color texel values shall modulate the color computed by lighting model:
%     glTexEnvfv(GL.TEXTURE_ENV,GL.TEXTURE_ENV_MODE,GL.REPLACE);
% 
%     % Clamping behaviour shall be a cyclic repeat:
%     glTexParameteri(gltextarget, GL.TEXTURE_WRAP_S, GL.REPEAT);
%     glTexParameteri(gltextarget, GL.TEXTURE_WRAP_T, GL.REPEAT);
% 
%     % Enable mip-mapping and generate the mipmap pyramid:
%     glTexParameteri(gltextarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
%     glTexParameteri(gltextarget, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
%     glGenerateMipmapEXT(GL.TEXTURE_2D);
% 
%     Screen('EndOpenGL', win);
%   end
% 
%   telapsed = 0;
%   fcount = 0;


