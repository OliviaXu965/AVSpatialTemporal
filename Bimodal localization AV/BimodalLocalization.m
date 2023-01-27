%This script tests subjects' accuracy and precision in localizing co-occurring 
%visual and auditory stimuli. The visual stimulus is a blob and the auditory
%stimulus is a burst of Gaussian noise. Each stimulus will appear at four
%locations. Auditory and visual locations are not matched in physical space
%but in perceptual space.
%% Enter subject's name
clear all; close all; clc; rng('shuffle');

ExpInfo.subjID = [];
while isempty(ExpInfo.subjID) == 1
    try ExpInfo.subjID = input('Please enter participant ID#: ') ; %'s'
    catch
    end
end

%enter session number
ExpInfo.session = [];
while isempty(ExpInfo.session) == 1
    try ExpInfo.session = input('Please enter the session#: ') ; %'s'
    catch
    end
end

%load the data from AV_alignment 
addpath(genpath('/e/3.3/p3/hong/Desktop/Project5/Psychtoolbox'));
addpath(genpath('/e/3.3/p3/hong/Desktop/Project5/Matching task/Analysis/ET'));
D = load(['AV_alignment_sub' num2str(ExpInfo.subjID) '_dataSummary.mat'],...
    'AV_alignment_data');
%get the PSE for the two auditory standard stimuli
ExpInfo.matchedAloc     = D.AV_alignment_data{2}.estimatedP([2,4]); 
ExpInfo.sittingDistance = 105;
out1FileName            = ['BimodalLocalization_pre_sub', num2str(ExpInfo.subjID),...
                            '_session', num2str(ExpInfo.session)]; %create file name

%% Screen Setup 
%Canvas size = 53.5" x 40"= 135.8cm x 101.6cm
%Screen size by the project = 1024 pixels x 768 pixels
%so each centimeter has 7.54 pixels horizontally and 7.56 vertically
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 1);
[windowPtr,rect] = Screen('OpenWindow', 0, [1,1,1]);
%[windowPtr,rect] = Screen('OpenWindow', 0, [0,0,0],[100 100 1000 480]); % for testing
[ScreenInfo.xaxis, ScreenInfo.yaxis] = Screen('WindowSize',windowPtr);   
Screen('TextFont',windowPtr,'Times');
Screen('TextSize',windowPtr,35);
Screen('TextStyle',windowPtr,1); 

[center(1), center(2)]     = RectCenter(rect);
ScreenInfo.xmid            = center(1); % horizontal center
ScreenInfo.ymid            = center(2); % vertical center
ScreenInfo.backgroundColor = 0;
ScreenInfo.numPixels_perCM = 7.5;
ScreenInfo.liftingYaxis    = 300;
ScreenInfo.cursorColor     = [0,0,255]; %A: blue, V:red
ScreenInfo.dispModality    = 'A';
ScreenInfo.x_box_unity     = [-95, -32; 35, 98];
ScreenInfo.y_box_unity     = [-10, 22];

%fixation locations
ScreenInfo.x1_lb = ScreenInfo.xmid-7; ScreenInfo.x2_lb = ScreenInfo.xmid-1;
ScreenInfo.x1_ub = ScreenInfo.xmid+7; ScreenInfo.x2_ub = ScreenInfo.xmid+1;
ScreenInfo.y1_lb = ScreenInfo.yaxis-ScreenInfo.liftingYaxis-1;
ScreenInfo.y1_ub = ScreenInfo.yaxis-ScreenInfo.liftingYaxis+1;
ScreenInfo.y2_lb = ScreenInfo.yaxis-ScreenInfo.liftingYaxis-7;
ScreenInfo.y2_ub = ScreenInfo.yaxis-ScreenInfo.liftingYaxis+7;

%% Open the motorArduino
% motorArduino            = serial('/dev/cu.usbmodemFD1331'); 
motorArduino            = serial('/dev/cu.usbmodemFA1331'); 
motorArduino.Baudrate   = 9600;
motorArduino.StopBits   = 1;
motorArduino.Terminator = 'LF';
motorArduino.Parity     = 'none';
motorArduino.FlowControl= 'none';
fopen(motorArduino);
pause(2);
noOfSteps = 3200;  

%% open loudspeakers and create sound stimuli 
addpath(genpath(PsychtoolboxRoot))
PsychDefaultSetup(2);
% get correct sound card
InitializePsychSound
devices = PsychPortAudio('GetDevices');
our_device=devices(3).DeviceIndex;

%% create auditory stimuli
%white noise for mask noise
AudInfo.fs              = 44100;
audioSamples            = linspace(1,AudInfo.fs,AudInfo.fs);
maskNoiseDuration       = 2; %the duration of the mask sound depends the total steps
MotorNoiseRepeated      = MakeMaskingSound(AudInfo.fs*maskNoiseDuration);

% set sound duration for both sound stimulus and mask noise
duration_mask           = length(audioSamples)*maskNoiseDuration;
timeline_mask           = linspace(1,duration_mask,duration_mask);

%generate white noise (one audio output channel)
carrierSound_mask       = randn(1, max(timeline_mask)); 
%create adaptation sound (only one loudspeaker will play the white noise)
AudInfo.intensity_MNR   = 100; %how loud do we want the recorded motor noise be
AudInfo.MaskNoise       = [carrierSound_mask+AudInfo.intensity_MNR.*MotorNoiseRepeated;
                            zeros(size(carrierSound_mask))]; 
%windowed: sineWindow_mask.*carrierSound_mask %non-windowed: carrierSound_mask

%for gaussion white noise
standardFrequency_gwn       = 10;
AudInfo.adaptationDuration  = 0.1; %0.05 %the burst of sound will be displayed for 40 milliseconds
duration_gwn                = length(audioSamples)*AudInfo.adaptationDuration;
timeline_gwn                = linspace(1,duration_gwn,duration_gwn);
sineWindow_gwn              = sin(standardFrequency_gwn/2*2*pi*timeline_gwn/AudInfo.fs); 
carrierSound_gwn            = randn(1, max(timeline_gwn));
AudInfo.intensity_GWN       = 15;
AudInfo.GaussianWhiteNoise  = [zeros(size(carrierSound_gwn));...
                                 AudInfo.intensity_GWN.*sineWindow_gwn.*carrierSound_gwn]; 
pahandle                    = PsychPortAudio('Open', our_device, [], [], [], 2);%open device

%% define the visual stimuli
VSinfo.Distance         = -12:8:12; %in deg
VSinfo.temporalOffset   = [-300,-150,0,150,300]; 
VSinfo.numLocs          = length(VSinfo.Distance);
VSinfo.numFrames        = 6;
VSinfo.width            = 401; %(pixel) Increasing this value will make the cloud more blurry
VSinfo.boxSize          = 201; %This is the box size for each cloud.
VSinfo.intensity        = 10; %This determines the height of the clouds. Lowering this value will make
                                %them have lower contrast
%set the parameters for the visual stimuli, which consist of 10 gaussian blobs
VSinfo.blackScreen = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);
VSinfo.blankScreen = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);
x                  = 1:1:VSinfo.boxSize; y = x;
[X,Y]              = meshgrid(x,y);
cloud              = 1e2.*mvnpdf([X(:) Y(:)],[median(x) median(y)],...
                        [VSinfo.width 0; 0 VSinfo.width]);
VSinfo.Cloud       = 255.*VSinfo.intensity.*reshape(cloud,length(x),length(y)) + 1; 
VSinfo.blk_texture = Screen('MakeTexture', windowPtr, VSinfo.blackScreen,[],[],[],2);    

%% define the experiment information
%for each AV pair and response modality
%split across 3 sessions, they add up to 20 (7+7+6) per AV pair
if ExpInfo.session == 3; ExpInfo.numTrials = 6; 
else; ExpInfo.numTrials   = 7;  
end
ExpInfo.AVpairs_allComb   = combvec(1:length(ExpInfo.matchedAloc), 1:VSinfo.numLocs,...
                                1:length(VSinfo.temporalOffset)); 
                            %1st row: A loc, 2nd row: V loc, 3rd row: t_A - t_V
ExpInfo.numAVpairs        = size(ExpInfo.AVpairs_allComb, 2); %32 possible pairs 
ExpInfo.numTotalTrials    = ExpInfo.numTrials * ExpInfo.numAVpairs;

ExpInfo.numBlocks         = 4;
blocks                    = linspace(0,ExpInfo.numTotalTrials,ExpInfo.numBlocks+1); 
                                %split all the trials into 4 blocks
ExpInfo.breakTrials       = blocks(2:(end-1)); %add 3 breaks to the experiment
ExpInfo.numTrialsPerBlock = ExpInfo.numTotalTrials/ExpInfo.numBlocks;
%Put all different trial types together and shuffle them 
%For each block, each trial type is presented 80/16 = 5 times
ExpInfo.AVpairs_order     = [];
for i = 1:ExpInfo.numTrials
    ExpInfo.AVpairs_order = [ExpInfo.AVpairs_order, randperm(ExpInfo.numAVpairs,...
        ExpInfo.numAVpairs)]; 
end
ExpInfo.tV_relative_tA    = VSinfo.temporalOffset(ExpInfo.AVpairs_allComb(3,ExpInfo.AVpairs_order));
ExpInfo.bool_unityReport  = ones(1,ExpInfo.numTotalTrials);%1: insert unity judgment
%Given the order of trial types, find the corresponding V and the A locations
VSinfo.arrangedLocs_deg   = VSinfo.Distance(ExpInfo.AVpairs_allComb(2,...
                            ExpInfo.AVpairs_order));
VSinfo.arrangedLocs_cm    = round(tan(deg2rad(VSinfo.arrangedLocs_deg)).*...
                            ExpInfo.sittingDistance,2);

%% calculate auditory locations
AudInfo.Distance         = round(ExpInfo.matchedAloc,2); %in deg
AudInfo.InitialLoc       = -7.5; %in deg
AudInfo.arrangedLocs_deg = AudInfo.Distance(ExpInfo.AVpairs_allComb(1,ExpInfo.AVpairs_order));
%create a matrix whose 1st column is initial position and 2nd column is final position
AudInfo.Location_Matrix   = [[AudInfo.InitialLoc, AudInfo.arrangedLocs_deg(1:end-1)]',...
                                 AudInfo.arrangedLocs_deg'];
[AudInfo.locations_wMidStep,AudInfo.moving_locations_steps, AudInfo.totalSteps] =...
                            randomPath2(AudInfo.Location_Matrix, ExpInfo); %1 midpoint, 2 steps
AudInfo.waitTime          = 0.5; 
%initialize a structure that stores all the responses and response time
[Response.localization, Response.RT1, Response.unity, Response.RT2] = ...
    deal(NaN(1,ExpInfo.numTotalTrials));  

%% Run the experiment by calling the function InterleavedStaircase
%start the experiment
DrawFormattedText(windowPtr, 'Press any button to start the bimodal localization task.',...
    'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,[255 255 255]);
Screen('Flip',windowPtr);
KbWait(-3); WaitSecs(1);
Screen('Flip',windowPtr);

for i = 1:ExpInfo.numTotalTrials 
    %present multisensory stimuli
    [Response.localization(i), Response.RT1(i), Response.unity(i),...
        Response.RT2(i)] = PresentMultisensoryStimuli(i,ExpInfo,ScreenInfo,...
        VSinfo, AudInfo,motorArduino,noOfSteps,pahandle,windowPtr);  
    %add breaks     
    if ismember(i,ExpInfo.breakTrials)
        Screen('TextSize', windowPtr, 35);
        DrawFormattedText(windowPtr, 'You''ve finished one block. Please take a break.',...
            'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis-30,...
            [255 255 255]);
        DrawFormattedText(windowPtr, 'Press any button to resume the experiment.',...
            'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,...
            [255 255 255]);
        Screen('Flip',windowPtr); KbWait(-3); WaitSecs(1);
        Screen('Flip',windowPtr); WaitSecs(0.5);
    end  
end

%% Move the arduino to the leftmost place
if abs(AudInfo.InitialLoc - AudInfo.Location_Matrix(end))>=0.01
    steps_goingBack = round((tan(deg2rad(AudInfo.InitialLoc))-...
                      tan(deg2rad(AudInfo.Location_Matrix(end))))*...
                      ExpInfo.sittingDistance/3,2);
    if steps_goingBack < 0 
        fprintf(motorArduino,['%c','%d'], ['p',noOfSteps*abs(steps_goingBack)]);
    else
        fprintf(motorArduino,['%c','%d'], ['n',noOfSteps*abs(steps_goingBack)]);
    end 
end
delete(motorArduino)
ShowCursor;

%% Save data and end the experiment
BimodalLocalization_pre_data = {ExpInfo, ScreenInfo, VSinfo, AudInfo, Response};
save(out1FileName,'BimodalLocalization_pre_data');
Screen('CloseAll');
