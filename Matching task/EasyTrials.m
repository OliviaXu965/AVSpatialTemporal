function [Resp,RT] = EasyTrials(currentLoc_A, destinatedLoc_A,destinatedLoc_V,...
    Order,ScreenInfo,VSinfo,AudInfo,ExpInfo,motorArduino,trailSteps,pahandle,windowPtr)      
    %----------------------------------------------------------------------
    %-----------Calculate the coordinates of the target stimuli------------
    %----------------------------------------------------------------------
    Vloc_cm   = round(tan(deg2rad(destinatedLoc_V))*ExpInfo.sittingDistance,4);
    targetLoc = round(ScreenInfo.xmid + ScreenInfo.numPixels_perCM.*Vloc_cm);

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
    else
        fprintf(motorArduino,['%c','%d'], ['n', trailSteps*abs(moving_steps)]);
    end
    WaitSecs(AudInfo.waitTime);
    PsychPortAudio('Stop', pahandle);

    %----------------------------------------------------------------------
    %---------------------display audiovisual stimuli----------------------
    %----------------------------------------------------------------------
    %show fixation cross for 1 s and then a blank screen for 2 s
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
            ScreenInfo.y1_lb,ScreenInfo.x1_ub,ScreenInfo.y1_ub]);
    Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
            ScreenInfo.y2_lb,ScreenInfo.x2_ub,ScreenInfo.y2_ub]);
    Screen('Flip',windowPtr); WaitSecs(0.5);
    Screen('Flip',windowPtr); WaitSecs(0.5);

    if Order == 2   %present the V first
        for j = 1:VSinfo.numFrames
            Screen('DrawTexture',windowPtr,dotCloud,[],[0,0,ScreenInfo.xaxis,...
                ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end 
        
        for k = 1:30 %500ms blank screen
            Screen('DrawTexture',windowPtr, VSinfo.blk_texture,[],...
                [0,0,ScreenInfo.xaxis, ScreenInfo.yaxis]);
            Screen('Flip',windowPtr);
        end
        
        %show fixation cross for 1 s and then a blank screen for 2 s
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
            ScreenInfo.y1_lb,ScreenInfo.x1_ub,ScreenInfo.y1_ub]);
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
            ScreenInfo.y2_lb,ScreenInfo.x2_ub,ScreenInfo.y2_ub]);
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
        
        %show fixation cross for 1 s and then a blank screen for 2 s
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x1_lb,...
            ScreenInfo.y1_lb,ScreenInfo.x1_ub,ScreenInfo.y1_ub]);
        Screen('FillRect', windowPtr,[255 255 255], [ScreenInfo.x2_lb,...
            ScreenInfo.y2_lb,ScreenInfo.x2_ub,ScreenInfo.y2_ub]);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        Screen('Flip',windowPtr); WaitSecs(0.5);
        
        for j = 1:VSinfo.numFrames
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
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis-30,[255 255 255]);
    DrawFormattedText(windowPtr, 'Left: press 1',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis,[255 255 255]);
    DrawFormattedText(windowPtr, 'Right: press 2',...
        'center',ScreenInfo.yaxis-ScreenInfo.liftingYaxis+30,[255 255 255]);
    Screen('Flip',windowPtr); WaitSecs(0.1);  

    KbName('UnifyKeyNames'); tic
    while 1  
        % record response
        [~, keyCode, ~] = KbWait(-3);
        pressedKey = KbName(keyCode);
        RT = toc;

        %When space bar is pressed
        if strcmpi(pressedKey, '1') == 1 %change it back to 1
            Resp = -1; break;
        elseif strcmpi(pressedKey, '2') == 1 %change it back to 2
            Resp = 1; break;  
        end  
        WaitSecs(0.1);
    end
    Screen('Flip',windowPtr);
    WaitSecs(0.1);
end
     