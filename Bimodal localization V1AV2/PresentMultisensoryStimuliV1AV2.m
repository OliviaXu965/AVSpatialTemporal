function [localization, RT1, binaryResp, RT2] = PresentMultisensoryStimuliV1AV2(...
    TrialNum, ExpInfo, ScreenInfo, VSinfo, AudInfo, motorArduino, ...
    numRailSteps, pahandle, windowPtr)
    %----------------------------------------------------------------------
    %-----------Calculate the coordinates of the target stimuli------------
    %----------------------------------------------------------------------
    %display visual stimuli
    targetLocV1 = round(ScreenInfo.xmid + ScreenInfo.numPixels_perCM.*...
                VSinfo.arrangedLocsV1_cm(TrialNum));
    targetLocV2 = round(ScreenInfo.xmid + ScreenInfo.numPixels_perCM.*...
                VSinfo.arrangedLocsV2_cm(TrialNum));
    
    %Make visual stimuli
    blob_coordinates1 = [targetLocV1, ScreenInfo.liftingYaxis];    
    dotCloud_V1 = generateOneBlob(windowPtr,blob_coordinates1,VSinfo,ScreenInfo);
    blob_coordinates2 = [targetLocV2, ScreenInfo.liftingYaxis];    
    dotCloud_V2 = generateOneBlob(windowPtr,blob_coordinates2,VSinfo,ScreenInfo);

    %----------------------------------------------------------------------
    %--------------Move the motor to the correct location------------------
    %----------------------------------------------------------------------
    %display Mask Noise
    PsychPortAudio('FillBuffer', pahandle, AudInfo.MaskNoise);
    PsychPortAudio('Start', pahandle, 0, 0, 1);
    
    %calculate the wait time
    movingSteps = AudInfo.moving_locations_steps(TrialNum,:); 
    waitTime1   = FindWaitTime(movingSteps);    
    %move the speaker to the location we want 
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

    %show fixation cross for 0.1 s and then a blank screen for 0.5 s
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
        ScreenInfo.y1_lb, ScreenInfo.x1_ub, ScreenInfo.y1_ub]);
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
        ScreenInfo.y2_lb, ScreenInfo.x2_ub, ScreenInfo.y2_ub]);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    
    %----------------------------------------------------------------------
    %------------------t_A = t_V1; they occur BEFORE V2--------------------
    %----------------------------------------------------------------------
    if ExpInfo.tV1tAtV2(TrialNum) == 1 && ExpInfo.tV2_rlt_tV1(TrialNum) > 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tV2_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        %present V1 and A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture', windowPtr, dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        PsychPortAudio('Stop', pahandle);
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present V2
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture', windowPtr, dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
    %----------------------------------------------------------------------
    %------------------t_A = t_V1; they occur AFTER V2---------------------
    %----------------------------------------------------------------------
    elseif ExpInfo.tV1tAtV2(TrialNum) == 1 && ExpInfo.tV2_rlt_tV1(TrialNum) < 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tV2_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        %present V2
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture', windowPtr, dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present V1 and A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture', windowPtr, dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        PsychPortAudio('Stop', pahandle);
    %----------------------------------------------------------------------
    %-------------------t_A = t_V2; they occur AFTER V1--------------------
    %----------------------------------------------------------------------
    elseif ExpInfo.tV1tAtV2(TrialNum) == 2 && ExpInfo.tV2_rlt_tV1(TrialNum) > 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tV2_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        %present V1
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present V2 and A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        PsychPortAudio('Stop', pahandle);
    %----------------------------------------------------------------------
    %------------------t_A = t_V2; they occur BEFORE V1--------------------
    %----------------------------------------------------------------------
    elseif ExpInfo.tV1tAtV2(TrialNum) == 2 && ExpInfo.tV2_rlt_tV1(TrialNum) < 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tV2_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        
        %present V2 and A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        PsychPortAudio('Stop', pahandle);
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present V1
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
    %----------------------------------------------------------------------
    %----------------A is presented in between V1 and V2-------------------
    %----------------------------------------------------------------------
    elseif ExpInfo.tV1tAtV2(TrialNum) == 0 && ExpInfo.tV2_rlt_tV1(TrialNum) > 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tA_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        
        %present V1
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);    
        WaitSecs(0.1); 
        PsychPortAudio('Stop', pahandle);
        
        %present blank screen
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present V2
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
    %----------------------------------------------------------------------
    %----------------A is presented in between V2 and V1-------------------
    %----------------------------------------------------------------------
    elseif ExpInfo.tV1tAtV2(TrialNum) == 0 && ExpInfo.tV2_rlt_tV1(TrialNum) < 0
        %given the SOA, calculate how many frames we present the blank screen
        SOA_frames = abs(ExpInfo.tA_rlt_tV1(TrialNum))/(1000/60); %1000ms/60Hz
        %present V2
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V2,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        %present A
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);    
        WaitSecs(0.1); 
        PsychPortAudio('Stop', pahandle);
        
        %present blank screen 
        for j = 1:SOA_frames 
            Screen('DrawTexture',windowPtr,VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        %present V1
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr,dotCloud_V1,[],...
                [0,0,ScreenInfo.xaxis,ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
    end
    
    %----------------------------------------------------------------------
    %--------------Record response using the pointing device---------------
    %----------------------------------------------------------------------
    Screen('Flip',windowPtr); WaitSecs(0.5);
    yLoc = ScreenInfo.yaxis-ScreenInfo.liftingYaxis;
    Screen('TextSize', windowPtr, 12);
    SetMouse(randi(ScreenInfo.xmid*2,1), yLoc, windowPtr); 
    buttons = zeros(1,16); tic
    %localize the stimulus using a visual cursor
    while buttons(1) == 0
        [x,~,buttons] = GetMouse; HideCursor;
        Screen('FillRect', windowPtr, ScreenInfo.cursorColor,...
            [x-3 yLoc-24 x+3 yLoc-12]);
        Screen('FillPoly', windowPtr, ScreenInfo.cursorColor,...
            [x-3 yLoc-12; x yLoc; x+3 yLoc-12]);
        Screen('DrawText', windowPtr, ScreenInfo.dispModality,...
            x-5, yLoc-30,[255 255 255]);
        Screen('Flip',windowPtr);
    end
    RT1            = toc;
    Response_pixel = x;
    Response_cm    = (Response_pixel - ScreenInfo.xmid)/ScreenInfo.numPixels_perCM;
    localization   = rad2deg(atan(Response_cm/ExpInfo.sittingDistance));
    Screen('Flip',windowPtr); WaitSecs(0.1);
    
    %Unity judgment
    if ExpInfo.bool_unityReport(TrialNum) == 1
        Screen('TextSize', windowPtr, 25);
        click = 0; tic
        while click == 0
            Screen('FillRect', windowPtr, [0,0,0],[x-3 yLoc-100 x+3 yLoc-100]);
            Screen('DrawText', windowPtr, 'VL        OR        VR',...
                ScreenInfo.xmid-89.5, yLoc-10,[255 255 255]);
            Screen('DrawText', windowPtr, 'Both',ScreenInfo.xmid-16,yLoc-80,[255 255 255]);
            Screen('DrawText', windowPtr, 'None',ScreenInfo.xmid-16,yLoc+60,[255 255 255]);
            Screen('Flip',windowPtr);
            [click,~,~, button] = GetClicks;
        end
        RT2 = toc;
        switch button
            case 1; binaryResp = 1; %A belongs to V1
            case 2; binaryResp = 2; %A belongs to V2
            case 5; binaryResp = 3; %A belongs to both visual stimuli
            case 4; binaryResp = 0; %A belongs to neither of these stimuli
        end
        %show a white frame to confirm the choice
        x_shift = ScreenInfo.x_box_unity(button,:);
        y_shift = ScreenInfo.y_box_unity(button,:);

        Screen('DrawText', windowPtr, 'VL        OR        VR',...
            ScreenInfo.xmid-89.5, yLoc-10,[255 255 255]);
            Screen('DrawText', windowPtr, 'Both',ScreenInfo.xmid-16,yLoc-80,[255 255 255]);
            Screen('DrawText', windowPtr, 'None',ScreenInfo.xmid-16,yLoc+60,[255 255 255]);
        Screen('FrameRect', windowPtr, [255,255,255], [ScreenInfo.xmid + x_shift(1),...
            yLoc-10 + y_shift(1), ScreenInfo.xmid + x_shift(2), yLoc-10 + y_shift(2)]);
        Screen('Flip',windowPtr); WaitSecs(0.1);
        Screen('Flip',windowPtr); WaitSecs(0.1);
    else
        binaryResp = NaN; RT2 = NaN; 
    end
end
    
    