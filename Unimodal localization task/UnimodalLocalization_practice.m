%This script tests subjects' accuracy and precision in localizing visual
%and auditory stimuli. The visual stimulus is a blob and the auditory
%stimulus is a burst of white noise. Each stimulus will appear at four
%locations. Auditory and visual locations are not matched in physical space
%but in perceptual space.

%% Enter subject's name
clear all; close all; clc; rng('shuffle');
addpath(genpath('/e/3.3/p3/hong/Desktop/Project5/Psychtoolbox'));

ExpInfo.subjID = [];
while isempty(ExpInfo.subjID) == 1
    try ExpInfo.subjID = input('Please enter participant ID#: ') ; %'s'
    catch
    end
end

%load the data from AV_alignment 
addpath(genpath('/e/3.3/p3/hong/Desktop/Project5/Matching task/Analysis/PW'));
D = load(['AV_alignment_sub' num2str(ExpInfo.subjID) '_dataSummary.mat'],...
    'AV_alignment_data');
%get the PSE for the two auditory standard stimuli
ExpInfo.matchedAloc     = D.AV_alignment_data{2}.estimatedP([2,4]); 
ExpInfo.sittingDistance = 105;
out1FileName            = ['Unimodal_localization_practice_sub',...
                            num2str(ExpInfo.subjID)];

%% Screen Setup 
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 1);
[windowPtr,rect] = Screen('OpenWindow', 0, [5,5,5]);
%[windowPtr,rect] = Screen('OpenWindow', 0, [5,5,5],[100 100 1000 480]); % for testing
[ScreenInfo.xaxis, ScreenInfo.yaxis] = Screen('WindowSize',windowPtr);
Screen('TextSize', windowPtr, 35) ;   
Screen('TextFont',windowPtr,'Times');
Screen('TextStyle',windowPtr,1); 

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

%% Open the motorArduino
%motorArduino            = serial('/dev/cu.usbmodemFD1331');
motorArduino             = serial('/dev/cu.usbmodemFA1331');
motorArduino.Baudrate   = 9600;
motorArduino.StopBits   = 1;
motorArduino.Terminator = 'LF';
motorArduino.Parity     = 'none';
motorArduino.FlowControl= 'none';
fopen(motorArduino);
pause(2);
noOfSteps = 3200;  

%% open loudspeakers and create sound stimuli 
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

%% Specify the locations of the auditory stimulus
% store the differences between standard and test four locations
AudInfo.Distance        = round(ExpInfo.matchedAloc,2); %in deg
AudInfo.InitialLoc      = -7.5;
AudInfo.numLocs         = length(AudInfo.Distance); 
AudInfo.numTrialsPerLoc = 2; %2 for practice, 30 for the real experiment
AudInfo.numTotalTrials  = AudInfo.numTrialsPerLoc * AudInfo.numLocs;
%the order of presenting V/A (if 1: A; %if 2: V)
%Even when the trial is V, we still move the speaker
ExpInfo.order_VSnAS     = [];
for i = 1:AudInfo.numTotalTrials
    ExpInfo.order_VSnAS = [ExpInfo.order_VSnAS, randperm(2,2)]; 
end
%Even when we present visual stimuli, we still move the speaker, so
%participants will have no expectation of which stimulus is coming up.
AudInfo.trialConditions = NaN(1,AudInfo.numTotalTrials*2);
AudInfo.trialConditions(ExpInfo.order_VSnAS==1) = ...
    Shuffle(repmat(AudInfo.Distance,[1, AudInfo.numTrialsPerLoc]));
AudInfo.trialConditions(ExpInfo.order_VSnAS==2) = ...
    Shuffle(repmat(AudInfo.Distance,[1, AudInfo.numTrialsPerLoc]));

%1st row: location (in deg)
%2nd row: responses (in deg)
%3rd row: response time
AudInfo.data      = zeros(3,AudInfo.numTotalTrials);
AudInfo.data(1,:) = AudInfo.trialConditions(ExpInfo.order_VSnAS==1); %in deg
%create a matrix whose 1st column is initial position and 2nd column is final position
AudInfo.Location_Matrix = [[AudInfo.InitialLoc, AudInfo.trialConditions(1:end-1)]',...
                                 AudInfo.trialConditions'];
[AudInfo.locations_wMidStep,AudInfo.moving_locations_steps, AudInfo.totalSteps] =...
    randomPath2(AudInfo.Location_Matrix, ExpInfo); %1 midpoint, 2 steps
AudInfo.waitTime         = 0.5; 

%% define the locatons of visual stimuli
VSinfo.initialDistance  = -12:8:12; %in deg, 4 visual locations
VSinfo.numLocs          = length(VSinfo.initialDistance);
VSinfo.numTrialsPerLoc  = AudInfo.numTrialsPerLoc/2; %since there are only 2 A locations
VSinfo.numFrames        = 6;
VSinfo.width            = 401; %(pixel) Increasing this value will make the cloud more blurry
VSinfo.boxSize          = 201; %This is the box size for each cloud.
VSinfo.intensity        = 10; %This determines the height of the clouds. Lowering this value will make
                                %them have lower contrast
                                
%set the parameters for the visual stimuli, which consist of 1 gaussian blob
VSinfo.blackScreen = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);
VSinfo.blankScreen = ones(ScreenInfo.xaxis,ScreenInfo.yaxis);
x                  = 1:1:VSinfo.boxSize; y = x;
[X,Y]              = meshgrid(x,y);
cloud              = 1e2.*mvnpdf([X(:) Y(:)],[median(x) median(y)],...
                        [VSinfo.width 0; 0 VSinfo.width]);
VSinfo.Cloud       = 255.*VSinfo.intensity.*reshape(cloud,length(x),length(y)) + 1; 
VSinfo.blk_texture = Screen('MakeTexture', windowPtr, VSinfo.blackScreen,[],[],[],2);    

%date_easyTrials stores all the data for randomly inserted easy trials
%1st row: the target will appear at either of the four locations (in deg)
%2nd row: the target location (in cm)
%3rd row: response (in deg)
%4th row: Response time
VSinfo.numTotalTrials = VSinfo.numTrialsPerLoc*VSinfo.numLocs;
VSinfo.data           = zeros(4,VSinfo.numTotalTrials);
VSinfo.data(1,:)      = Shuffle(VSinfo.initialDistance);
VSinfo.data(2,:)      = tan(deg2rad(VSinfo.data(1,:))).*ExpInfo.sittingDistance;

%% Run the experiment by calling the function InterleavedStaircase
%start the experiment
DrawFormattedText(windowPtr, 'Press any button to start the unimodal localization task.',...
    'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,[255 255 255]);
Screen('Flip',windowPtr); 
KbWait(-3); WaitSecs(1);
Screen('Flip',windowPtr);

for i = 1:(AudInfo.numTotalTrials+VSinfo.numTotalTrials) 
    if ExpInfo.order_VSnAS(i) == 1 %auditory trial
        jj = sum(ExpInfo.order_VSnAS(1:i)==1);
        [AudInfo.data(2,jj), AudInfo.data(3,jj)] = PresentAuditoryStimulus(i,...
            ExpInfo,ScreenInfo,AudInfo,motorArduino,noOfSteps,pahandle,windowPtr);
    else %visual trial
        ii = sum(ExpInfo.order_VSnAS(1:i)==2);
        [VSinfo.data(3,ii),VSinfo.data(4,ii)] = PresentVisualStimulus(i,ii,...
            ExpInfo,ScreenInfo,VSinfo,AudInfo,motorArduino,noOfSteps,pahandle,...
            windowPtr);
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
Unimodal_localization_data = {ExpInfo,ScreenInfo,VSinfo,AudInfo};
save(out1FileName,'Unimodal_localization_data');
Screen('CloseAll');
