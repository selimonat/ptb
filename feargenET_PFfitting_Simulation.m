function [p,PM]=feargenET_PFfitting_Simulation(subject,   csp_degree)

p = [];
SetParams;
SetPTB;

%Set up running fit procedure:

%% Define prior
priorAlphaRange = linspace(0,180,100); %values of alpha to include in prior
priorBetaRange = linspace(-5,5,100);  %values of log_10(beta) to include in prior

%Stimulus values to select from (need not be equally spaced)
stimRange = [0:22.5:180]; 

%2-D Gaussian prior
prior = repmat(PAL_pdfNormal(priorAlphaRange,60,60),[length(priorBetaRange) 1]).* repmat(PAL_pdfNormal(priorBetaRange',0,4),[1 length(priorAlphaRange)]);

prior = prior./sum(sum(prior)); %prior should sum to 1


%Termination rule
stopcriterion = 'trials';
stoprule      = 50;

%Function to be fitted during procedure
PFfit = @PAL_CumulativeNormal;    %Shape to be assumed
gamma = 0.5;            %Guess rate to be assumed
lambda = .00;           %Lapse Rate to be assumed

%set up procedure
PM = [];

TrueThreshold   = 33;
tchain = 4;
for nc = 1:tchain
%set up procedure
PM{nc} = PAL_AMPM_setupPM('priorAlphaRange',priorAlphaRange,...
    'priorBetaRange',priorBetaRange, 'numtrials',stoprule, 'PF' , PFfit,...
    'prior',prior,'stimRange',stimRange,'gamma',gamma,'lambda',lambda);

PM{nc}.xrounded         = nan(p.stim.tFace,stoprule);
PM{nc}.trial_counter    = zeros(1,p.stim.tFace/2);

factornoise             = 5;
PM{nc}.noise            = nc*factornoise;


end
%need 4 PF, 1) cs+ local, 2)cs- local, 3) cs+ foreign, 4) cs-foreign



while (PM{1}.stop ~= 1) || (PM{2}.stop ~= 1) || (PM{3}.stop ~= 1) || (PM{4}.stop ~= 1)
    
    current_chain = randsample(1:tchain,1);
   
    if PM{current_chain}.stop ~= 1
    %Present trial here at stimulus intensity UD.xCurrent and collect
    %response 
   
          
           if PAL_CumulativeNormal([alpha beta .5 0],PM{current_chain}.xCurrent)>randn(1)
               response = 1;
           else
               response = 0;
           end
    
    row                                    = round(PM{current_chain}.xCurrent/(720/p.stim.tFace)+1);
    PM{current_chain}.trial_counter(row)                                 = PM{current_chain}.trial_counter(row) + 1;
    PM{current_chain}.xrounded(row,PM{current_chain}.trial_counter(row)) = response;
    %updating PM
        PM{current_chain} = PAL_AMPM_updatePM(PM{current_chain},response);
        

    %plots (moved them to the end)
    end
  

end
    %save PM here
    save(p.path.path_param,'PM');
    % plot the Adaptive Procedure in different subplots and save it
    plot_proc;
    saveas(h,[p.path.subject 'stimulation\Output'],'png')
% Print summary of results to screen
for chain=1:tchain
fprintf('Chain %g: Estimated Threshold (alpha): %4.2f \n',chain,PM{chain}.threshold(length(PM{chain}.threshold)))
fprintf('Chain %g: Estimated Slope (beta): %4.2f \n',chain,PM{chain}.slope(length(PM{chain}.slope)));
end
%clear the screen
%close everything down
cleanup;
%move the folder to appropriate location
movefile(p.path.subject,p.path.finalsubject);


  function SetPTB
    debug =1;
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        screenNumber  =  max(screens);
        %make everything transparent for debuggin purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        Screen('Preference', 'SkipSyncTests', 0);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
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
        
        for nStim = 1:p.stim.tFile
                filename       = p.stim.files(nStim,:);
                [im , ~, ~]    = imread(filename);
                p.stim.stim(:,:,nStim)    = rgb2gray(im);
                p.ptb.stim_sprites(nStim)     = Screen('MakeTexture', p.ptb.w, im );
        end
        p.stim.delta = 720/p.stim.tFile;
    end
  function SetParams
    
        %
        p.var.timings                 = zeros(1,10);
        p_var_event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\PsychToolbox\Documents\onat\Experiments\';
        else
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'FearGeneralization_Ethnic\'];
        p.path.stimfolder             = 'ethno_pilote\32faces';
        p.path.stim                   = [p.path.baselocation 'Stimuli\Gradients\' p.path.stimfolder '\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'pmf']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\PM']);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
     
          dummy = dir([p.path.stim '*.bmp']);
            p.stim.files    = [repmat([fileparts(p.path.stim) filesep],length(dummy),1) vertcat(dummy(:).name)];
            p.stim.label = {dummy(:).name};  
        
        
        p.stim.tFile                  = size(p.stim.files,1);%number of different files
        p.stim.tFace                  = p.stim.tFile;%number of faces.
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %set the background gray according to the background of the stimuli
        for i = 1:p.stim.tFile;
            im                        = imread(p.stim.files(i,:));
            bg(i)                     = im(1,1,1);
        end
        %is all the captured bg values the same?
        if sum(diff(bg))==0;
            %if so take it as the bg color
            p.stim.bg                   = double([bg(1) bg(1) bg(1)]);
        else
            fprintf('background luminance was not successfully detected...\n')
            keyboard;
        end
        %
        %font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;%30;
        %rating business
        p.rating.division              = 2;%number of divisions for the rating slider
        %
        p.stim.white                   = [255 255 255];
        %get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        
        if strcmp(p.hostname,'triostim1')
            p.keys.confirm                 = KbName('7');
            p.keys.increase                = KbName('8');
            p.keys.decrease                = KbName('6');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('up');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
        end
        
       
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 1.5;%s     
        p.duration.pink                = .5;
        p.duration.gray                = 2;
%         if simulation_mode
%             p.duration.stim                = .01;%s
%             p.duration.pink                = .01;
%             p.duration.gray                = .01;
%         end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %create the randomized design
        p.stim.cs_plus                 = csp_degree;%index of cs stimulus, this is the one paired to shock
%         p.stim.cs_neg                  = csn;
      

        event_onsets = 0.15;
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.gray];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];

        p.trial.onsets = event_onsets;
%         p.out.rating                  = [];
%         p.out.log                     = zeros(stoprule*4,4).*NaN;

        %Save the stuff
        save(p.path.path_param,'p');
        
        %

  end
 
  function plot_proc
      
    h=figure('name','Running Fit Adaptive Procedure and Parameters');
    for sub=1:4
    subplot(2,4,sub)
    title(['Procedure chain ',num2str(sub)])
    t = 1:length(PM{sub}.x);
    subplot(2,4,sub); hold on; 
    plot(t,PM{sub}.x,'k');
    plot(t(PM{sub}.response == 1),PM{sub}.x(PM{sub}.response == 1),'ko', ...
        'MarkerFaceColor','k');
    plot(t(PM{sub}.response == 0),PM{sub}.x(PM{sub}.response == 0),'ko', ...
        'MarkerFaceColor','w');
    set(gca,'FontSize',12);
    axis([0 stoprule+1 0 max(PM{sub}.x)]) 
    xlabel('Trial');
    ylabel('xCurrent (Deg)');
    subplot(2,4,sub+4)
    title(['\alpha/\beta chain ',num2str(sub)])
    imagesc(PM{sub}.pdf); hold on;
    h1 = gca;
    set(h1, 'Xtick',[0:25:100], 'XtickLabel', {'0','45','90','135','180'},...
        'Ytick',[0:25:100], 'YtickLabel', {'-5','-2.5','0','2.5','5'});
  
    xlabel('Alpha');
    ylabel('Log(Beta)');
    drawnow
    
    end
  end

  function cleanup
        
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
%         %IOPort('ConfigureSerialPort', p.com.serial,' StopBackgroundRead');
%         %IOPort('Close',p.com.serial);
%         commandwindow;
%         ListenChar(0);
%         KbQueueRelease(p_ptb_device);
  end
  end