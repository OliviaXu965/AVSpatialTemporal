function [Resp, RT, updatedLoc_A] = InterleavedStaircases(Conditions,...
    trialNum, currentLoc_A, inputResp, destinatedLoc_A, ScreenInfo, ExpInfo,...
    VSinfo, AudInfo, Order, motorArduino, trailSteps, pahandle, windowPtr)
    %----------------------------------------------------------------------
    %-----------Calculate the coordinates of the target stimuli------------
    %----------------------------------------------------------------------
    Vloc_idx  = fix((Conditions+1)/2);
    Vloc      = VSinfo.locations_cm(Vloc_idx);
    targetLoc = round(ScreenInfo.xmid + ScreenInfo.numPixels_perCM.*Vloc);

    %Make visual stimuli
    blob_coordinates = [targetLoc, ScreenInfo.liftingYaxis];
    dotCloud = generateOneBlob(windowPtr,blob_coordinates,VSinfo,ScreenInfo);

    %----------------------------------------------------------------------
    %--------------Move the motor to the correct location------------------
    %----------------------------------------------------------------------
    %display Mask Noise
    PsychPortAudio('FillBuffer', pahandle, AudInfo.MaskNoise);
    PsychPortAudio('Start', pahandle, 0, 0, 1);
    
    %calculate the wait time
    moving_steps = round((tan(deg2rad(destinatedLoc_A))-...
        tan(deg2rad(currentLoc_A)))*ExpInfo.sittingDistance/3,2);    
    %move the speaker to the location we want 
    if moving_steps < 0 
        fprintf(motorArduino,['%c','%d'], ['p', trailSteps*abs(moving_steps)]);
    %when AuditoryLoc is negative, move to the left
    else
        fprintf(motorArduino,['%c','%d'], ['n', trailSteps*abs(moving_steps)]);
    end
    WaitSecs(AudInfo.waitTime);
    PsychPortAudio('Stop', pahandle);

    %----------------------------------------------------------------------
    %---------------------display audiovisual stimuli----------------------
    %----------------------------------------------------------------------
    %show fixation cross for 0.5 s and then a blank screen for 1 s
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
        ScreenInfo.y1_lb, ScreenInfo.x1_ub, ScreenInfo.y1_ub]);
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
        ScreenInfo.y2_lb, ScreenInfo.x2_ub, ScreenInfo.y2_ub]);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    
    if Order == 2 %present the V first
        for j = 1:VSinfo.numFrames 
            Screen('DrawTexture',windowPtr, dotCloud,[],[0,0,ScreenInfo.xaxis,...
                ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        for k = 1:30 %500ms blank screen
            Screen('DrawTexture',windowPtr, VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis, ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end

        %show fixation cross for 0.5 s and then a blank screen for 1 s
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
            ScreenInfo.y1_lb, ScreenInfo.x1_ub, ScreenInfo.y1_ub]);
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
            ScreenInfo.y2_lb, ScreenInfo.x2_ub, ScreenInfo.y2_ub]);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);    
        WaitSecs(0.5); 
        PsychPortAudio('Stop', pahandle);
        
    else %present the A first
        PsychPortAudio('FillBuffer', pahandle, AudInfo.GaussianWhiteNoise);
        PsychPortAudio('Start', pahandle, 1, 0, 0);    
        WaitSecs(0.5); 
        PsychPortAudio('Stop', pahandle);
        
        %show fixation cross for 0.5 s and then a blank screen for 1 s
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
            ScreenInfo.y1_lb, ScreenInfo.x1_ub, ScreenInfo.y1_ub]);
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
            ScreenInfo.y2_lb, ScreenInfo.x2_ub, ScreenInfo.y2_ub]);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        
        for j = 1:VSinfo.numFrames 
            %Screen('DrawDots', windowPtr, dots_standardLoc_coordinates,4,[250 250 250]);
            Screen('DrawTexture',windowPtr,dotCloud,[],[0,0,ScreenInfo.xaxis,...
                ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        for k = 1:30 %500ms blank screen
            Screen('DrawTexture',windowPtr, VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis, ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end
    end
    
    %----------------------------------------------------------------------
    %---------------------Record and update responses----------------------
    %----------------------------------------------------------------------    
    %record response and RTs
    DrawFormattedText(windowPtr, 'Is the A to the left or right of the V?',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis-60,[255 255 255]);
    DrawFormattedText(windowPtr, 'Left: press 1',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis-30,[255 255 255]);
    DrawFormattedText(windowPtr, 'Right: press 2',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,[255 255 255]);
    Screen('Flip',windowPtr); WaitSecs(0.1);  

    KbName('UnifyKeyNames'); tic
    while 1  
        % record response
        [~, keyCode, ~] = KbWait(-3);
        pressedKey = KbName(keyCode);
        RT = toc;
        %When space bar is pressed
        if strcmpi(pressedKey, '1') == 1 %1/1!
            Resp = -1; break;
        elseif strcmpi(pressedKey, '2') == 1 %2/2@
            Resp = 1; break;  
        end  
        WaitSecs(0.1);
    end
    Screen('Flip',windowPtr);
    WaitSecs(0.1);
    
    %----------------------------------------------------------------------
    %-------------Calculate the step size for the next trial---------------
    %----------------------------------------------------------------------     
    %find out the next distance
    updatedLoc_A = FindNextDistance(AudInfo, Conditions, trialNum, ...
        destinatedLoc_A, inputResp, Resp);   
    %no feedback 
end
    
