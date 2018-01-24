function [p]=exp_PainThreshold(subject,varargin)

clear mex global functions

if ~IsWindows
    %OUTP.m is used to communicate with the parallel port, mainly to send
    %triggers to the physio-computer or Digitimer device (which is used to give
    %shocks). OUTP is a cogent function, so it only works with Windows. In
    %Unix the same functionality can also be obtained with PTB, but it is not
    %coded in this program yet. So to communicate via the parallel port, there
    %are two options: 1/install cogent + outp, or 2/ use equivalent of OUTP
    %in PTB. This presentation will now replace the OUTP.m function with
    %the following code, which simply does nothing but allows the program
    %run.
    
    outp = @(x,y) 1;
end

% cgshut;
if ~isempty(varargin)
    debug = varargin{1};
else
    debug = 1;
end
global cogent;
%
p         = [];
log_threshold =[];
%
SetParams;
SetPTB;
SCRCheck;
MarkCED(p.lpt.address,p.lpt.InitExperiment);
GetThreshold;
save(p.path.filename,'p');
%%now give the subject a final shock with the "tobeused level" and ask
%%whether it is bearable.
factor = input('Enter the desired factor (for example 1.4). Start with the highest :).\n');
ConfirmIntensity(factor);
save(p.path.filename,'p');
%
ShowInstruction(6);

%move the file to its final location.
movefile(p.path.subject,p.path.finalsubject);
cleanup;


    function GetThreshold        
        %%base
        %message to show on the rating screen.
        message = 'War der Reiz schmerzhaft oder nicht?\nBewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und best?tige deine Einsch?tzung mit der mit der oberen Pfeiltaste.';
        %
        p.threshold.init.alphas        = linspace(-1,0,100);
        p.threshold.init.prior         = PAL_pdfNormal(p.threshold.init.alphas, log10(.6), .1);
        p.threshold.init.stopcriterion = 'trials';
        p.threshold.init.stoprule      = 1;
        p.threshold.init.PFfit         = @PAL_CumulativeNormal;
        p.threshold.init.beta          = 3.5;
        p.threshold.init.lambda        = 0;
        p.threshold.init.gamma         = 0;
        p.threshold.init.meanmode      = 'mode';
        p.threshold.final.factor       = [1.5 2 2.5];
        %
        p.threshold.RF = PAL_AMRF_setupRF('priorAlphaRange', p.threshold.init.alphas, 'prior', p.threshold.init.prior,...
            'stopCriterion',p.threshold.init.stopcriterion,'stoprule',p.threshold.init.stoprule,'beta',p.threshold.init.beta,'gamma',p.threshold.init.gamma,...
            'lambda',p.threshold.init.lambda,'PF',p.threshold.init.PFfit,'meanmode',p.threshold.init.meanmode);
        %
        p.threshold.RF.xCurrent        = log10(.5);%start shock;
        plot(10.^p.threshold.RF.priorAlphaRange,p.threshold.RF.pdf,'r')
        %%
        %
        response_mapping = [1 0];
        ShowInstruction(4);
        %
        fprintf('Press a key to start\n')
        [secs, keyCode, deltaSecs] = KbStrokeWait;
        %
        counter = 0;
        close all;
        while ~p.threshold.RF.stop
            %
            counter         = counter + 1;
            amplitude       = 10.^p.threshold.RF.xCurrent;
            %
            fprintf([repmat('=',1,50) '\n']);
            fprintf('SHOCK No: %d of %d.\n',counter,p.threshold.init.stoprule);            
            fprintf('    The intensity is now: %g\n',10.^p.threshold.RF.xCurrent);            
            fprintf('    Or escape to quit prematurely.\n');
            %                        
            ShowInstruction(5);%shock is coming message, stays ~2 sec...
            %prepare for the shock
            MarkCED(p.lpt.address,p.lpt.ShockOnset)
            t               = GetSecs + p.duration.shock;
            Buzz(amplitude);
            %Ask for rating
            [response]      = RatingSlider(p.ptb.rect,2,Shuffle(1:2,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nschmerzhaft' 'schmerzhaft'},message,0);
            response        = response_mapping(response);
            %
            response        = logical(response);
            amplitude       = p.threshold.RF.xCurrent;
            p.threshold.RF  = PAL_AMRF_updateRF(p.threshold.RF, amplitude, response);
            %
            figure(1)
            plot(10.^p.threshold.RF.priorAlphaRange,p.threshold.RF.pdf,'r')
            set(gca,'xScale','log')
            drawnow;            
        end
        log_threshold   = p.threshold.RF.(p.threshold.init.meanmode);
        p.threshold.final.estimated       = 10.^log_threshold;
        
        fprintf('\n\n\nRESULT:\n');
        fprintf('The estimated loudness threshold: %g\n',p.threshold.final.estimated);
        fprintf('Choose an intensity:\n');
        fprintf('Intensity to be used for factor x 1.2): %g mA\n',10.^(log_threshold/1.2));
        fprintf('Intensity to be used for factor x 1.3): %g mA\n',10.^(log_threshold/1.3));
        fprintf('Intensity to be used for factor x 1.4): %g mA\n',10.^(log_threshold/1.4));
        fprintf('We will now ask whether this is bearable...\n');                
    end
    function ConfirmIntensity(factor)
        %        
        I = 10.^(log_threshold/factor);        
        %
        ShowInstruction(1);
        %
        fprintf([repmat('=',1,50) '\n']);
        fprintf('TEST PULSE:\n');        
        fprintf('    The intensity is now: %g\n',I);        
        fprintf([repmat('=',1,50) '\n']);
        %
%         [secs, keyCode, deltaSecs] = KbStrokeWait;
        ShowInstruction(5);%shock is coming message...
        MarkCED(p.lpt.address,p.lpt.ShockOnset)
        t         = GetSecs + p.duration.shock;        
        Buzz(I);        
        %
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und best?tige deine Einsch?tzung mit der mit der oberen Pfeiltaste.';
        [p.threshold.confirmation.response] = RatingSlider(p.ptb.rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertr?glich' 'ertr?glich'},message,0);
        if p.threshold.confirmation.response == 1
            fprintf('All is fine :)\n');
            fprintf('Subject confirmed the shock intensity...\n')
            cprintf([0 1 0],'INTENSITY TO BE USED FOR THE MAIN EXPERIMENT: %g mA\n',I);
            p.threshold.final.tobeused = I;
            return;
        elseif p.threshold.confirmation.response == 2
            cprintf([1 0 0],'Shit... :(, %g is too much for the subject\n',I);
            fprintf('We will try a little milder intensity.\n');
            factor = factor - 0.05;
            ConfirmIntensity(factor);
        end
        
        
    end
    function SetParams
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        p.path.baselocation  = '/Users/onat/Documents/Experiments/';
        p.path.experiment    = [p.path.baselocation 'LoudnessThreshold/'];
        %
        p.name              = subject;
        timestamp           = datestr(now,30);
        p.path.subject      = [p.path.experiment 'data/tmp/' p.name '_' timestamp '/'];
        p.path.finalsubject = [p.path.experiment 'data/' p.name '_' timestamp ];
        mkdir(p.path.subject);
        p.path.filename          = [regexprep(p.path.subject,'\\','\\\') 'param.mat' ];
        %font size and background gray level
        p.text.fontname          = 'Times New Roman';
        p.text.fontsize              = 30;
        %where to place text on the screen;
        p.text.start_x =  60;
        p.textstart_y  =  275;
        %
        p.stim.bg                = [0.47 0.47 0.47]*255;%background color
        p.stim.bg_rating         = [0 0.47 0].*255;
        p.stim.white             = [255 255 255];
        p.stim.crossy            = 30;%crosshair position
        %
        p.size_RatingScale   = 200;%size of the rating scale in pixels. The actual size is 2x.
        %All settings for laptop computer.
        p.keys.confirm    = KbName('UpArrow');
        p.keys.increase   = KbName('RightArrow');
        p.keys.decrease   = KbName('LeftArrow');
        p.keys.space      = KbName('space');
        p.keys.esc        = KbName('ESCAPE');
        %parallel port
        p.lpt.address       = 888;
        p.lpt.digitimer     = 128;                
        p.lpt.ShockOnset    = 16;   
        p.lpt.InitExperiment = 64;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        p.duration.shock           = 0.1;%s;x
        p.duration.shockpulse      = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse = 0.01;%ms; and the time between each pulse
        
        %
        %Save the stuff
        save(p.path.filename,'p');
    end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [nx ny bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
            Screen('FillRect',p.ptb.w,p.stim.bg);
        end
        bb = max(bb);
        bb_size = bb(3)-bb(1);%vertical size of the bb.
        %
        DrawSkala;
        ok = 1;
        while ok == 1
            [secs, keyCode, deltaSecs] = KbStrokeWait;
            
            keyCode = find(keyCode);
            if (keyCode == up) | (keyCode == down)
                next = position + increment(keyCode);
                if next < (tSection+1) & next > 0
                    position = position + increment(keyCode);
                    rating   = tSection - position + 1;
                end
                DrawSkala;
            elseif keyCode == confirm
                WaitSecs(0.1);
                ok = 0;
                Screen('FillRect',p.ptb.w,p.stim.bg);
                Screen('Flip',p.ptb.w);
            end
        end
        
        function DrawSkala
            rating               = tSection - position + 1;
            increment([up down]) = [1 -1];%delta
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize./2);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.2,rect(2), p.stim.white);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.2,rect(2), p.stim.white);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize./2);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            Screen('Flip',p.ptb.w);
        end
    end
    function ShowInstruction(nInstruct)
        
        [text]=GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed. But we don't
        %need that in the case of INSTRUCT = 5;
        if nInstruct == 5 %this is for the Reiz kommnt
            WaitSecs(0.5+rand(1));
        elseif nInstruct == 6
            WaitSecs(3);
        else
            KbStrokeWait;
        end
        Screen('FillRect',p.ptb.w,p.stim.bg);
        Screen('Flip',p.ptb.w);
        function ShowText(text)
            
            
            Screen('FillRect',p.ptb.w,p.stim.bg);
            %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.stim.white,[],[],[],2,[]);
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            Screen('Flip',p.ptb.w);
            
            %show the messages at the experimenter screen
            fprintf([repmat('=',1,50) '\n']);
            fprintf('Subject''s monitor:\n');
            fprintf(text);
            fprintf([repmat('=',1,50) '\n']);
            
        end
        function [text]=GetText(nInstruct);
            if nInstruct == 1%Baseline Phase
                %=================================================================================================================%
                text = ['Gib bitte an ob die Reizst?rke des folgenden Schocks\nf?r dich ertr?glich ist.\n'...
                    '\n'...
                    'Dr?cke bitte die mittlere Taste um den Reiz zu bekommen.\n'...
                    ];
                
                
            elseif nInstruct == 4%shock calibration
                text = ['Wir werden nun deine Schmerzschwelle bestimmen.\n'...
                    '\n'...
                    'Daf?r wirst du mehrere (~10) elektrische Reize bekommen.\n' ...
                    '\n'...
                    'Bitte gib jeweils nach jedem Reiz an, ob er schmerzhaft war oder nicht.\n'...
                    '\n'...
                    'Wenn du noch fragen hast, kannst du jetzt den Versuchsleiter fragen.\n'...
                    '\n'...
                    'Dr?cke ansonsten die mittlere Taste,\n'...
                    '   um das Experiment fortzusetzen.\n' ...
                    ];
            elseif nInstruct == 5%just before the shock
                text = ['Reiz kommt...\n'];
            elseif nInstruct == 6%transition.
                
                text = ['Damit ist dieser Teil zu Ende.\n' ...
                    '\n'...
                    'Wir machen nun mit der n?chsten Phase weiter.\n'...
                    ];
                
            else
                text = {''};
            end
        end
    end
    function SetPTB
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        screenNumber  =  max(screens)
        %make everything transparent for debuggin purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %
        [p.ptb.w ]                  = Screen('OpenWindow', screenNumber, p.stim.bg);
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', screenNumber);
        %find the mid position.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        %area of the slider
        p.ptb.rect                  = [p.ptb.midpoint(1)*0.5  p.ptb.midpoint(2)*0.8 p.ptb.midpoint(1) p.ptb.midpoint(2)*0.2];
        %compute the cross position.
        [nx ny bb] = DrawFormattedText(p.ptb.w,'+','center','center');
        Screen('FillRect',p.ptb.w,p.stim.bg);
        p.ptb.cross_shift           = [45 50];%upper and lower cross positions
        p.ptb.CrossPosition_y       = [ny-p.ptb.cross_shift(1)  ny+p.ptb.cross_shift(2) ];
        p.ptb.CrossPosition_x       = [bb(1) bb(1)];
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        %
        Priority(MaxPriority(p.ptb.w));
        %prepare parallel port communication. This relies on cogent i
        %think.
        outp(p.lpt.address,0);
    end
    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end
    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end
    function Buzz(amplitude)
        FS           = 44000;
        total_length = FS*3;
        D            = 8;
        Y            = demean(rand(1,total_length)).*repmat([ones(1,total_length/D/2)*amplitude ones(1,total_length/D/2)*.01],1,D);
        sound(Y,FS)
    end
    function cleanup
        % Close window:
        sca;
        commandwindow;
    end
    function SCRCheck
        fprintf([repmat('!',1,50) '\n']);
        fprintf([repmat('!',1,50) '\n']);
        fprintf([repmat('!',1,50) '\n']);
        fprintf('Did you TURN ON the SCR ????\n Press a key to continue...\n');
        KbStrokeWait;
    end
end
