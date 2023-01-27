%% pre-exposure: ternary temporal order judgement task

% 2022/04/v3
% Equipment indices are set to work on Chartest with the projector, central
% speaker and number pad.

% For calibration, Psychportaudio was delayed by 32.53 ms.

% Participants will complete a 3-alternative-force-choice (3AFC) ternary
% task (Ulrich, 1987; García-Pérez & Alcalá-Quintana, 2012; Yarrow, Martin,
% Di Costa, Solomon, & Arnold, 2016). In each trial, they will be presented
% with audiovisual stimulus pair with various stimulus onset asynchronies
% (SOA), ranging from [-400, -300:50:300, 400] ms. A positive SOA refers
% to a visual lead and a negative SOA refers to an auditory lead. After the
% stimulus presentation, participants will report whether they perceive
% that the auditory stimulus precede the visual stimulus (‘A-precedes-V’
% response), both stimuli occur at the same time (‘A-coincides-V’
% response), or the visual stimulus precedes the auditory stimulus
% (‘A-follows-V’ response) by a button press. Each of the SOAs will be
% randomly interleaved within a method of a constant stimuli and presented
% 25 times, resulting in a total of 375 trials.

% Response guide:
% 1: V-first
% 2: simultaneous
% 3: A-first

% numLock: exit the experiment during response period

addpath(genpath('/e/3.3/p3/hong/Desktop/Project5/Psychtoolbox'));
try
    %% enter subject's name
    clear all; close all; clc; rng('shuffle');
    
    %enter subject's name
    ExpInfo.subjID = [];
    while isempty(ExpInfo.subjID) == 1
        ExpInfo.subjID = input('Please enter participant ID#: ') ; %'s'
    end
    
    % choose device indices
    ExpInfo.sittingDistance = 105; %in cm, the distance between the screen and participants
    out1FileName = ['TOJ_Practice_sub', num2str(ExpInfo.subjID)]; %create file name
    
    % avoid rewriting data
    if exist([out1FileName '.mat'],'file')
        resp=input('To replace the existing file, press y', 's');
        if ~strcmp(resp,'y')
            disp('Experiment stopped.')
            return
        end
    end
    
    %% define parameters
    % define bias
    ExpInfo.bias = 0.03253;

    % define SOA as the time difference between two stimulus onsets
    dur_perFrame   = 1000/60; %16.6666 ms
    ExpInfo.SOA    = [-450-dur_perFrame, (-350-dur_perFrame):(3*dur_perFrame):(-150-dur_perFrame),...
        (-100 -dur_perFrame):(2*dur_perFrame):(100 +dur_perFrame),...
        (150 + dur_perFrame):(3*dur_perFrame):(350+dur_perFrame), 450 + dur_perFrame] /1000; %s
    ExpInfo.numSOA = length(ExpInfo.SOA);

    % trial number per SOA level
    ExpInfo.numTrials        = 1;
    
    % sound and blob presented the same duration
    % make sure the SOA increment is larger than stimulus duration
    ExpInfo.stimFrame        = 6; % frame
    
    % define duration ranges by lower bound and higher bound
    ExpInfo.fixation         = .5;
    ExpInfo.blankDuration1   = 1; % between fixation and the first stimulus
    ExpInfo.blankDuration2   = 1; % between stimulus offset and response probe
    ExpInfo.ITI              = .5;
    
    %% define the experiment information
    ExpInfo.numTotalTrials   = ExpInfo.numTrials * ExpInfo.numSOA;
    ExpInfo.trialSOA         = Shuffle(ExpInfo.SOA);
    
    %initialize a structure that stores all the responses and response time
    [Response.order, Response.RT] = deal(NaN(1,ExpInfo.numTotalTrials));
    
    %% screen setup
    PsychDefaultSetup(2);
    AssertOpenGL();
    GetSecs();
    WaitSecs(0.1);
    KbCheck();
    ListenChar(2); % silence the keyboard
    HideCursor();
    
    %Canvas size = 53.5" x 40"= 135.8cm x 101.6cm Screen size by the project =
    %1024 pixels x 768 pixels so each centimeter has 7.54 pixels horizontally
    %and 7.56 vertically
    Screen('Preference', 'VisualDebugLevel', 1);
    Screen('Preference', 'SkipSyncTests', 1);
    [windowPtr,rect] = Screen('OpenWindow', 0, [1,1,1]); % 1 = external display
%     [windowPtr,rect] = Screen('OpenWindow', ExpInfo.deviceIndices(1), [255, 255, 255]./10, [100 100 1000 600]); % for testing
    ScreenInfo.topPriorityLevel = MaxPriority(windowPtr);
    [ScreenInfo.xaxis, ScreenInfo.yaxis] = Screen('WindowSize',windowPtr);
    Screen('TextSize', windowPtr, 25) ;
    Screen('TextFont',windowPtr,'Times');
    Screen('TextStyle',windowPtr,1);
    ScreenInfo.frameRate=Screen('FrameRate',0);
    ScreenInfo.ifi = Screen('GetFlipInterval', windowPtr);
    [center(1), center(2)]     = RectCenter(rect);
    ScreenInfo.xmid            = center(1); % horizontal center
    ScreenInfo.ymid            = center(2); % vertical center
    ScreenInfo.backgroundColor = 0;
    ScreenInfo.numPixels_perCM = 7.5;
    ScreenInfo.liftingYaxis    = 300;
  
    %fixation locations
    ScreenInfo.x1_lb = ScreenInfo.xmid-7; ScreenInfo.x2_lb = ScreenInfo.xmid-1;
    ScreenInfo.x1_ub = ScreenInfo.xmid+7; ScreenInfo.x2_ub = ScreenInfo.xmid+1;
    ScreenInfo.y1_lb = ScreenInfo.yaxis-ScreenInfo.liftingYaxis-1;
    ScreenInfo.y1_ub = ScreenInfo.yaxis-ScreenInfo.liftingYaxis+1;
    ScreenInfo.y2_lb = ScreenInfo.yaxis-ScreenInfo.liftingYaxis-7;
    ScreenInfo.y2_ub = ScreenInfo.yaxis-ScreenInfo.liftingYaxis+7;
    
    %% open loudspeakers and create sound stimuli
    addpath(genpath(PsychtoolboxRoot))
    PsychDefaultSetup(2);
    % get correct sound card
    InitializePsychSound
    devices                    = PsychPortAudio('GetDevices');
    our_device                 = devices(3).DeviceIndex;
    % sampling frequencies
    AudInfo.fs                 = 44100;
    audioSamples               = linspace(1,AudInfo.fs,AudInfo.fs);
    % make a beep
    standardFrequency_gwn      = 10;
    AudInfo.adaptationDuration = 0.1;
    duration_gwn               = length(audioSamples)*AudInfo.adaptationDuration;
    timeline_gwn               = linspace(1,duration_gwn, duration_gwn);
    sineWindow_gwn             = sin(standardFrequency_gwn/2*2*pi*timeline_gwn/AudInfo.fs);
    carrierSound_gwn           = randn(1, max(timeline_gwn));
    AudInfo.intensity_GWN      = 15;
    AudInfo.GaussianWhiteNoise = [zeros(size(carrierSound_gwn));...
        AudInfo.intensity_GWN.*sineWindow_gwn.*carrierSound_gwn];
    pahandle = PsychPortAudio('Open', our_device, [], [], [], 2);%open device
    
    % initialize driver, request low-latency preinit:
    InitializePsychSound(1);
    
    % Perform one warmup trial, to get the sound hardware fully up and running,
    % performing whatever lazy initialization only happens at real first use.
    % This "useless" warmup will allow for lower latency for start of playback
    % during actual use of the audio driver in the real trials:
    PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
    PsychPortAudio('Start', pahandle, 0, 0, 1);
    PsychPortAudio('Stop', pahandle, 1);
    
    %% define the visual stimuli
    VSinfo.duration      = ExpInfo.stimFrame * ScreenInfo.ifi;%s
    VSinfo.width         = 401; %(pixel) Increasing this value will make the cloud more blurry
    VSinfo.boxSize       = 201; %This is the box size for each cloud.
    VSinfo.testIntensity = 10; %This determines the contrast of the clouds. 

    %set the parameters for the visual stimuli
    VSinfo.blackScreen   = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);
    VSinfo.blankScreen   = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);%zeros(ScreenInfo.xaxis,ScreenInfo.yaxis);
    x                    = 1:1:VSinfo.boxSize; y = x;
    [X,Y]                = meshgrid(x,y);
    cloud                = 1e2.*mvnpdf([X(:) Y(:)],[median(x) median(y)],...
                            [VSinfo.width 0; 0 VSinfo.width]);
    VSinfo.Cloud         = 255.*VSinfo.testIntensity.*reshape(cloud,...
                            length(x),length(y))+1;
    VSinfo.blk_texture   = Screen('MakeTexture', windowPtr, ...
                            VSinfo.blackScreen,[],[],[],2);
    
    %% Run the experiment by calling the function InterleavedStaircase
    %  record tart time
    c = clock;
    start = sprintf('%04d/%02d/%02d_%02d:%02d:%02d',c(1),c(2),c(3),c(4),c(5),ceil(c(6)));
    timestamp{1,1} = start;
    
    % start the experiment
    DrawFormattedText(windowPtr, 'Press any button to start the temporal order judgement task.',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,[255 255 255]);
    Screen('Flip',windowPtr);
    KbWait(-3); WaitSecs(1);
    Screen('Flip',windowPtr);
    
    for i = 1:ExpInfo.numTotalTrials   
        %present multisensory stimuli
        [Response.order(i), Response.RT(i)]...
            = PresentMultisensoryStimuliTest_TOJ(i,ExpInfo,ScreenInfo,...
            VSinfo, AudInfo,pahandle,windowPtr);
    end
    
    %% Finish the experiment
    % end time
    c = clock;
    finish = sprintf('%04d/%02d/%02d_%02d:%02d:%02d',c(1),c(2),c(3),c(4),c(5),ceil(c(6)));
    timestamp{2,1} = finish;
    % save data
    save(out1FileName,'Response', 'ExpInfo', 'ScreenInfo',...
        'VSinfo', 'AudInfo', 'pahandle', 'windowPtr','timestamp');
    ShowCursor();
    Screen('CloseAll');
    ListenChar(0);
    
catch e
    psychError = psychlasterror();
    save('error.mat','e','psychError')
    ShowCursor();
    Screen('CloseAll');
    ListenChar(0);
    psychrethrow(psychlasterror);
end