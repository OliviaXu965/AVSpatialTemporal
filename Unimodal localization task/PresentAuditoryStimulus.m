%This script controls the location of the motor and display auditory
%stimulus
function [Response_deg, RT]=PresentAuditoryStimulus(trialNum,ExpInfo,...
    ScreenInfo,AudInfo,motorArduino,numRailSteps,pahandle,windowPtr)
    %----------------------------------------------------------------------
    %--------------Move the motor to the correct location------------------
    %----------------------------------------------------------------------    
    %display Mask Noise
    PsychPortAudio('FillBuffer', pahandle, AudInfo.MaskNoise);
    PsychPortAudio('Start', pahandle, 0, 0, 1);
    
    %move the speaker to the location we want
    movingSteps = AudInfo.moving_locations_steps(trialNum,:); 
    waitTime1   = FindWaitTime(movingSteps);
    for s = 1:length(movingSteps)
        if movingSteps(s) < 0  %when AuditoryLoc is negative, move to the left
            fprintf(motorArduino,['%c','%d'], ['p', numRailSteps*abs(movingSteps(s))]);
        else
            fprintf(motorArduino,['%c','%d'], ['n', numRailSteps*movingSteps(s)]);
        end
        %wait shortly
        WaitSecs(waitTime1(s));
    end
    %wait shortly
    WaitSecs(AudInfo.waitTime);
    PsychPortAudio('Stop', pahandle);

    %----------------------------------------------------------------------
    %------------------------display auditory stimuli----------------------
    %----------------------------------------------------------------------
    %show fixation cross for 1 s and then a blank screen for 2 s
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,ScreenInfo.y1_lb,...
        ScreenInfo.x1_ub, ScreenInfo.y1_ub]);
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,ScreenInfo.y2_lb,...
        ScreenInfo.x2_ub, ScreenInfo.y2_ub]);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    Screen('Flip',windowPtr); WaitSecs(0.5); 

    PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
    PsychPortAudio('Start', pahandle, 1, 0, 0);
    WaitSecs(AudInfo.adaptationDuration);
    PsychPortAudio('Stop', pahandle);
    
    %black screen for 0.5 seconds
    Screen('Flip',windowPtr);
    WaitSecs(0.5);
    
    %----------------------------------------------------------------------
    %--------------Record response using the pointing device---------------
    %---------------------------------------------------------------------- 
    yLoc = ScreenInfo.yaxis-ScreenInfo.liftingYaxis;
    SetMouse(randi(ScreenInfo.xmid*2,1), yLoc, windowPtr); buttons = 0;
    tic
    while sum(buttons)==0
        [x,~,buttons] = GetMouse; HideCursor;
        Screen('FillRect', windowPtr, [0 300 0],[x-3 yLoc-24 x+3 yLoc-12]);
        Screen('FillPoly', windowPtr, [0 300 0],[x-3 yLoc-12; x yLoc; x+3 yLoc-12]);
        Screen('Flip',windowPtr,0,0);
    end
    Response_pixel = x;
    Response_cm    = (Response_pixel -  ScreenInfo.xmid)/ScreenInfo.numPixels_perCM;
    Response_deg   = rad2deg(atan(Response_cm/ExpInfo.sittingDistance));
    RT             = toc;
    %blank screen for 1 seconds
    Screen('Flip',windowPtr); WaitSecs(0.5);
end
    
   