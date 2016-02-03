function [p]=exp_fearamy_PFfitting_constant(subject,phase,csp_degree)

% Diskrimination Task estimating the Threshold alpha of an
% observer's underlying Psychometric Function (PF), using constant stimuli.
% Enter the subject Number as well as the CS+ Face in Degrees (where 00 is
% 1st face, and so), optional input choses version (fixcrossjumps vs. free
% viewing)
simulation_mode = 0;
fixjump         = 1;
% make a break every ....th Trial
breakpoint      = 50;

ListenChar(2);%disable pressed keys to be spitted around
commandwindow;
%clear everything
clear mex global functions
cgshut;
global cogent;
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);

el = [];
p  = [];
SetParams;
SetPTB;

InitEyeLink;
WaitSecs(2);
ShowInstruction(1);
%calibrate if we are at the scanner computer.
if strcmp(p.hostname,'triostim1') || strcmp(p.hostname,'etpc');
     CalibrateEL;
end
SetupLog;
%save the parameter file
save(p.path.path_param,'p');
ShowInstruction(3);
% counter for within chain trials (cc) and global trials (tt)
cc = zeros(1,tchain);
tt = 0;
%trialID is counting every single face (2 per Trial_YN), need that for
%Eyelink
trialID = 0;


STOP = 0;
while ~STOP
  chains = find(cc<p.psi.presentation.numtrials_chain);
  if length(chains) == 1
      current_chain = chains;
  elseif length(chains) >1
      current_chain = RandSample(chains,[1 1]);
  end
  if tt~=tchain*p.psi.presentation.numtrials_chain
      tt=tt+1;
      % enter in break loop
      if (tt~=1 && mod(tt,breakpoint)==1 && simulation_mode==0);
          save(p.path.path_param,'p');
          ShowInstruction(4);
          CalibrateEL;
      end
      cc(current_chain)=cc(current_chain)+1;
      fprintf('Chain %4.2f , Chain trial %03d/%03d...',current_chain,cc(current_chain),p.psi.presentation.numtrials_chain)
      
      %Present trial here at stimulus intensity x and collect
      %response
      fprintf('x is now %4.2f \n',x(cc(current_chain),current_chain))
      test      = x(cc(current_chain),current_chain) + csn_shift(current_chain) + csp_degree;
      dummy     = test;
      test      = mod(test,360);
      % the reference is csp or csn
      ref       = csn_shift(current_chain) + csp_degree;
      ref       = mod(ref,360);
      
      % start Trial
      fprintf('Starting Trial %03d/%03d.\n',tt,tchain*p.psi.presentation.numtrials_chain)
      
      [test_face, ref_face, signal,trialID] = Trial_YN(trialID,ref,test,p.stim.tFace,tt);
      
      fprintf('Rating.\n')
      Screen('Textsize', p.ptb.w,p.text.fontsize);
      %Rating Slider
      %
      message1 = 'Waren die Gesichter unterschiedlich oder gleich?\n';
      message2 = 'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätigen Sie Ihre Einschätzung mit der oberen Pfeiltaste.';
      if ~simulation_mode
          rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
          [response_subj]      = RatingSlider(rect,2,Shuffle(1:2,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'unterschiedlich' 'gleich'},message1,message2,0);
          
          % see if subject found the different pair of faces...
          % buttonpress left (Yes) is response_subj=2, right alternative (No) outputs a 1.
          % note that response=1 only means "yes", and not correct or anything
          sdt = NaN;
          if (response_subj == 2 && signal == 1)
              response=1;
              fprintf('...Hit. \n')
              sdt=1;
          elseif (response_subj==1 && signal == 1)
              response=0;
              fprintf('...Miss. \n')
              sdt=3;
          elseif (response_subj == 2 && signal==0)
              response=1;
              fprintf('...False Alarm. \n')
              sdt=2;
          elseif (response_subj == 1 && signal == 0)
              response=0;
              fprintf('...Correct Rejection. \n')
              sdt=4;
          else
              fprintf('error in the answer algorithm! \n')
          end
          
      else
          true_a = 45;
          true_s = 5;
          true_g = 0.2;
          true_l = 0.02;
          response = ObserverResponseFunction(@PAL_CumulativeNormal,true_a,1/true_s,true_g,true_l,abs(x(cc(current_chain),current_chain)));
          sdt = nan;
      end
      
      % store everything in the Log
      row                                     = find(unique(x)==x(cc(current_chain),current_chain));
      p.psi.log.trial_counter(row,current_chain)    = p.psi.log.trial_counter(row,current_chain) + 1;
      p.psi.log.xrounded(row,p.psi.log.trial_counter(row,current_chain),current_chain) = response;
      SetLog;
      %iteration control
      STOP = sum(cc >= p.psi.presentation.numtrials_chain) == tchain;
  end
  %final save of parameter-/logfile
  save(p.path.path_param,'p');
end

%end of Experiment, shown to subject
ShowInstruction(2);
%Print summary of results to screen
% for chain=1:tchain
% fprintf('Chain %g: Estimated Threshold (alpha): %4.2f \n',chain,PM{chain}.threshold(end));
% fprintf('Chain %g: Estimated Slope (beta): %4.2f \n',chain,PM{chain}.slope(end));
% end
%get the eyelink file back to this computer
StopEyelink(p.path.edf);

%close everything down
cleanup;
%move the folder to appropriate location
movefile(p.path.subject,p.path.finalsubject);
% subplot(2,1,1)
% errorbar(p.psi.presentation.uniquex,nanmean(p.psi.log.xrounded(:,:,1),2),nanstd(p.psi.log.xrounded(:,:,1),0,2),'b.','MarkerSize',20)
% title('CSP chain')
% subplot(2,1,2)
% errorbar(p.psi.presentation.uniquex,nanmean(p.psi.log.xrounded(:,:,2),2),nanstd(p.psi.log.xrounded(:,:,2),0,2),'r.','MarkerSize',20)
% title('CSN chain')

    function  [test_face,ref_face,signal,trialID] = Trial_YN(trialID,ref_stim,test_stim,last_face_of_circle,tt)
        Screen('Textsize', p.ptb.w,p.text.fixsize);
        % computes the trial FACES, using the test/ref information input
        % values (in Deg)
        
        trial = [ref_stim test_stim]/p.stim.delta;
        % correct face number within circle
        trial      = mod(round(trial),last_face_of_circle)+1;
        ref_face   = trial(1);
        test_face  = trial(2);
        [trial,idx]= Shuffle(trial);
        fprintf('Faces: %d %d \n',trial(1),trial(2));
        %compute if trial had different faces or not
        %if trial(1)=trial(2), they were the same and subject has to
        %answer with 'no' (right option, is 1), else means correct hit
        
        if trial(1)==trial(2)
            signal = 0;
        else
            signal = 1;
        end
       
        
       trial_deg = [ref_stim test_stim];
       isref     = double(trial==ref_face) ;
       delta_ref   = MinimumAngleQuartile([trial_deg(idx(1)) trial_deg(idx(2))],ref);
       delta_csp   = MinimumAngleQuartile([trial_deg(idx(1)) trial_deg(idx(2))],csp_degree); % ...
       abs_FGangle = [trial_deg(idx(1)) trial_deg(idx(2))];
       
       trialID=trialID+1;

        %get fixation crosses and onsets from p parameter
        
               
        %GetSecs so that the onsets can be defined
        if fixjump ==1
            onsets = 0.25+GetSecs;                                   %fix1 onset
            onsets = [onsets onsets(end)+p.duration.fix+rand(1)*.25];%stim1 onset
            onsets = [onsets onsets(end)+p.duration.crossmoves];     %fix jump
            onsets = [onsets onsets(end)+p.duration.crossmoves];     %stim offset
            fixdelta = p.duration.fix+rand(1)*.25;
            onsets = [onsets onsets(end)+p.duration.isi-fixdelta];   %fix2 onset
            onsets = [onsets onsets(end)+fixdelta];                  %stim2 onset
            onsets = [onsets onsets(end)+p.duration.crossmoves];     %fix jump
            onsets = [onsets onsets(end)+p.duration.crossmoves];     %stim offset
        else
            onsets = 0.25+GetSecs;%fix1 onset
            onsets = [onsets onsets(end)+p.duration.fix+rand(1)*.25];%stim1 onset
            onsets = [onsets onsets(end)+p.duration.stim];%stim1 offset
            fixdelta = p.duration.fix+rand(1)*.25;
            onsets = [onsets onsets(end)+p.duration.isi-fixdelta];%fix2 onset
            onsets = [onsets onsets(end)+fixdelta];%stim2 onset
            onsets = [onsets onsets(end)+p.duration.stim];%stim2 offset
        end
        
        if fixjump ==1
            fix_i        = p.psi.presentation.fix_start(cc(current_chain),current_chain);
            fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
            FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
            %fixation cross 1
            %FixCross = [fix(1,1)-1,fix(1,2)-p.ptb.fc_size,fix(1,1)+1,fix(1,2)+p.ptb.fc_size;fix(1,1)-p.ptb.fc_size,fix(1,2)-1,fix(1,1)+p.ptb.fc_size,fix(1,2)+1];
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
            Screen('Flip',p.ptb.w,onsets(1),0);
            StartEyelinkRecording(trialID,phase,cc(current_chain),tt,current_chain,isref(1),trial(1),delta_ref(1),delta_csp(1),abs_FGangle(1),fix(1,1),fix(1,2));
            %face trial(1)
            Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(1)));
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Screen('Flip',p.ptb.w,onsets(2),0);
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
            %fixJUMP trial(1)
            fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(setdiff(1:2,fix_i))];%take the other position
            FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
            %FixCross = [fix(2,1)-1,fix(2,2)-p.ptb.fc_size,fix(2,1)+1,fix(2,2)+p.ptb.fc_size; fix(2,1)-p.ptb.fc_size,fix(2,2)-1,fix(2,1)+p.ptb.fc_size,fix(2,2)+1];
            Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(1)));
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Screen('Flip',p.ptb.w,onsets(3),0);
            while GetSecs<onsets(4)
            end
            Screen('Flip',p.ptb.w,onsets(4),0);
            StopEyelinkRecording;
            
            %second face of the trial
            trialID=trialID+1;
            %fixation cross 2
            fix_i        = p.psi.presentation.fix_start(cc(current_chain),current_chain);
            fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
            FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
            Screen('Flip',p.ptb.w,onsets(5),0);
            StartEyelinkRecording(trialID,phase,cc(current_chain),tt,current_chain,isref(2),trial(2),delta_ref(2),delta_csp(2),abs_FGangle(2),fix(1,1),fix(1,2));
            %face trial(1)
            Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(2)));
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Screen('Flip',p.ptb.w,onsets(6),0);
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
            %fixJUMP trial(1)
            fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(setdiff(1:2,fix_i))];%take the other position
            FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
            Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(2)));
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Screen('Flip',p.ptb.w,onsets(7),0);
            while GetSecs<onsets(8)
            end
            Screen('Flip',p.ptb.w,onsets(8),0);
            StopEyelinkRecording;
            
        elseif fixjump ==0;
            fix        = round(p.ptb.CrossPositions(tt,:));
            %fixation cross 1
            FixCross = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
            Screen('Flip',p.ptb.w,onsets(1),0);
            StartEyelinkRecording(trialID,phase,cc(current_chain),tt,current_chain,isref(1),trial(1),delta_ref(1),delta_csp(1),abs_FGangle(1),fix(1),fix(2));
            %face trial(1)
            Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(1)));
            Screen('Flip',p.ptb.w,onsets(2),0);
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
            while GetSecs < onsets(3)
            end
            Screen('Flip',p.ptb.w,onsets(3),0);
            StopEyelinkRecording;
            %second face of the trial
            trialID=trialID+1;
            %fixation cross 2
            FixCross = [fix(3)-1,fix(4)-p.ptb.fc_size,fix(3)+1,fix(4)+p.ptb.fc_size;fix(3)-p.ptb.fc_size,fix(4)-1,fix(3)+p.ptb.fc_size,fix(4)+1];
            Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
            Eyelink('Message', 'FX Onset at %d %d',fix(3),fix(4));
            Screen('Flip',p.ptb.w,onsets(4),0);
            StartEyelinkRecording(trialID,phase,cc(current_chain),tt,current_chain,isref(2),trial(2),delta_ref(2),delta_csp(2),abs_FGangle(2),fix(3),fix(4));
            %face trial(2)
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(trial(2)));
            Screen('Flip',p.ptb.w,onsets(5),0);
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
            while GetSecs<onsets(6)
            end
            Screen('Flip',p.ptb.w,onsets(6),0);
            StopEyelinkRecording;
            
        end
    end
    

    function SetPTB
    debug =0;
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        
        if strcmp(p.hostname,'etpc')
           p.ptb.screenNumber=1;
        else
           p.ptb.screenNumber=max(screens);
        end
        
       
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
        %
        if strcmp(p.hostname,'etpc')
            res          = [1600 1200];
        else
            res = [1920 1200];
        end
        p.ptb.oldres = Screen('Resolution',p.ptb.screenNumber,res(1),res(2));
        %hide the cursor
        %HideCursor(p.ptb.screenNumber);
        %spit out the resolution 
        if ~ismac
            fprintf('Resolution of the screen is set to %dx%d...\n',res(1),res(2));
        end
        %Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        if sum([p.ptb.width p.ptb.height] - [1280 960]) ~= 0
            fprintf('SET THE CORRECT SCREEN RESOLUTION\n');
        end
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.stim.width p.stim.height];
        p.ptb.cross_shift           = [180 -120];%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%always the same
        p.ptb.CrossPosition_y       = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];        
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        p.ptb.fc_size               = 10;
        % 
        if fixjump == 0
            p.ptb.CrossPositions   = FixationCrossPool;
        end

        Priority(MaxPriority(p.ptb.w));
        
        for nStim = 1:p.stim.tFile
                filename       = p.stim.files(nStim,:);
                [im , ~, ~]    = imread(filename);
                %what is this good for?
                if ndims(im) == 3
                    p.stim.stim(:,:,nStim)    = rgb2gray(im);
                else
                    p.stim.stim(:,:,nStim)    = im;
                end
                p.ptb.stim_sprites(nStim)     = Screen('MakeTexture', p.ptb.w, im );
        end
        p.stim.delta = 360/p.stim.tFile;
        
        %create tukeywindow for the pink noise fadeout
        w  =.3;
        p.ptb.tw = tukeywin(p.stim.height,w)*tukeywin(p.stim.height,w)';
        
        
        function  [cross_positions]=FixationCrossPool
            radius   = 590; %in px (around 14 degrees (37 px/deg))
            center   = [800 600];
            
            %setting up fixation cross pool vector of size
            % totaltrials x 4 (face_1_x face_1_y face_2_x face_2_y)
            cross_directions = round(rand(tchain*p.psi.presentation.numtrials_chain,2))*180;
            dummy            = cross_directions + rand(tchain*p.psi.presentation.numtrials_chain,2)*30-15;
            cross_positions  = [cosd(dummy(:,1))*radius+center(1) sind(dummy(:,1))*radius+center(2)...
                cosd(dummy(:,2))*radius+center(1) sind(dummy(:,2))*radius+center(2)];
        end
    end
 


    function SetParams
    
        %
        p.var.timings                 = zeros(1,10);
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        elseif strcmp(p.hostname,'isn3464a9d59588')
            p.path.baselocation       = 'C:\Users\user\Documents\Experiments\';
        else
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'FearAmy\'];
        p.path.stimfolder             = 'stim';
        p.path.stim                   = [p.path.experiment  p.path.stimfolder '\'];
        p.path.stim24                 = [p.path.experiment  p.path.stimfolder '\' '24bits' '\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = sprintf(['s%03dp%02d' ],subject,phase);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        p.path.dropbox                = 'C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\DiscriminationTask\pilotedata\data';
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'pmf']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\' 'p.mat']);
        
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
        p.text.fixsize                 = 60;
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
%         1.5 0.5 0.5
        p.duration.stim                = 1.5;%s     
        p.duration.fix                 = .7;
        p.duration.crossmoves          = p.duration.stim./2;   
        p.duration.isi                 = 1.0;
        if simulation_mode
            p.duration.stim                = .001;%s
            p.duration.crossmoves          = .001;
            p.duration.fix                 = .001;
            p.duration.isi                 = 0.001;
            %p.duration.gray                = .001;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %create the randomized design
        p.stim.cs_plus                 = csp_degree;%index of cs stimulus, this is the one paired to shock
        %p.stim.cs_neg                  = csn;
      

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Set up Constant Stimuli procedure
        csn_shift               = [0 180];
        tchain                  = 2;
        interval = 22.5;
        maxdegree = 180;
        maxtrials = 100;
        addzeros  = 18;
               
        tsteps = (2*maxdegree./interval)+1;
        if maxdegree == 180
            tsteps = tsteps - 2;%spares out the CSN
        end
        rep    = floor(maxtrials./(tsteps+1));%+1 so that zero can be doubled...
        steps  = [repmat(0:interval:180-interval,1,rep) repmat(0:interval:180-interval,1,rep)*-1 zeros(1,addzeros)];
        
        for n = 1:tchain
            x(:,n)          = Shuffle(steps);
            fix_start(:,n)  = seq_BalancedDist(x(:,n)',[1 2])';
        end
        
        fprintf('This is the distribution of stimuli we will use:\n')
        histi = histc(x,unique(x));
        uniquex = unique(x);
        for l = 1:length(unique(x))
        fprintf('Level %g: %02d repetitions. \n',uniquex(l,1),histi(l,1))
        end
        fprintf('---------------------------\nTotal trials: %03d per chain.\n',sum(histi(:,1)))
        WaitSecs(3);
        %store everything in p
        p.psi.presentation.x               = x;
        p.psi.presentation.interval        = interval;
        p.psi.presentation.numtrials_chain = length(x(:,1));
        p.psi.presentation.tsteps          = tsteps;
        p.psi.presentation.rep             = histi(:,1);
        p.psi.presentation.uniquex         = unique(x);
        p.psi.presentation.fix_start       = fix_start;
        p.var.current_bg                   = p.stim.bg;%current background to be used.
        %Save the stuff
        save(p.path.path_param,'p');
        %

  end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message1,message2,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [nx, ny, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
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
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.6,rect(2), p.stim.white);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.2,rect(2), p.stim.white);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message1, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize./2);
            DrawFormattedText(p.ptb.w,message2, 'center', p.ptb.midpoint(2)*0.4,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            Screen('Flip',p.ptb.w);
        end
    end

    function [shuffled,idx] = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end

    function [a]=MinimumAngleQuartile(y,x)
        %[a]=MinimumAngle(x,y);
        %
        %finds the minimum angle between two angles given in degrees, the answer is
        %also in degrees. The clockwise distances from Y to X are considered as
        %positive. Opposite angles are considered as positive 180.
        
        x  = deg2rad(x);
        y  = deg2rad(y);
        
        a  = atan2(sin(x-y), cos(x-y));
        
        a  = -round(((180/pi)*a)*4)/4;
        
        if any(abs(a) == 180);
            a(abs(a) == 180) = 180;
        end
    end

    function ShowInstruction(nInstruct)
        
        [text]=GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed.
        
        KbStrokeWait;
        
        Screen('FillRect',p.ptb.w,p.stim.bg);
        Screen('Flip',p.ptb.w);
        
    end
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


    function [text]=GetText(nInstruct)
        
        if nInstruct == 0%Eyetracking calibration
                
                text = ['Um Ihre Augenbewegungen zu messen, \n' ...
                        'müssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                        'Dazu zeigen wir Ihnen einige Punkte auf dem Bildschirm, \n' ...
                        'bei denen Sie sich wie folgt verhalten:\n' ...
                        'Bitte fixieren Sie den Fixationspunkt und \n' ...
                        'bleiben Sie so lange darauf, wie er zu sehen ist.\n' ...
                        'Bitte drücken Sie jetzt den oberen Knopf, \n' ...
                        'um mit der Kalibrierung weiterzumachen.\n' ...
                    ];
        
        elseif nInstruct == 1
            text = ['In diesem Experiment sehen Sie nacheinander zwei Gesichter.\n'...
                '\n'...
                'Danach werden Sie gefragt, ob die Gesichter unterschiedlich oder gleich waren.\n'...
                '\n'...
                'Benutzen Sie dazu die Pfeiltasten (links, rechts) und die obere Taste zum Bestätigen.\n'...
                '\n'...
                'Sie werden alle ' num2str(breakpoint) ' Durchgänge eine Pause machen können,\nnach der der Eyetracker neu kalibriert wird.\n'...
                '\n'...
                'Wenn Sie noch Fragen haben, können Sie jetzt die Versuchsleiterin fragen.\n'...
                'Wir können Sie jederzeit hören.\n'...
                '\n'...
                'Drücken Sie ansonsten die obere Taste,\n'...
                '   um das Experiment zu starten.\n' ...
                ];
        elseif nInstruct == 3
            text = ['Der Eyetracker ist nun kalibiert.\n'...
                '\n'...
                'Bitte verändern Sie Ihre Kopfposition nun nicht mehr.\n'...
                '\n'...
                'Im Experiment sehen Sie jeweils zwei Gesichter und geben anschließend an,\n'...
                '\n'...
                'ob die Gesichter gleich oder unterschiedlich waren.\n'...
                '\n'...
                'Benutzen Sie dazu die Pfeiltasten (links, rechts) und die obere Taste zum Bestätigen.\n'...
                '\n'...
                'Drücken Sie nun die obere Taste,\n'...
                '   um das Experiment zu starten!\n' ...
                ];
        elseif nInstruct == 2%end
            text = 'Experiment beendet!\n';
            
        elseif nInstruct==4%break
            text = [sprintf('Sie haben bereits %g von %g Durchgängen geschafft!\n',tt-1,p.psi.presentation.numtrials_chain*tchain)...
                'Machen Sie eine kurze Pause, lehnen Sie sich gern einen Moment zurück\n'...
                'und schließen Sie die Augen, um diese zu entspannen.\n'...
                'Drücken Sie anschließend die mittlere Taste, um weiterzumachen.\n'];
        end
    end
       
    function SetupLog
        
        p.psi.log.globaltrial= NaN(tchain,length(x));
        p.psi.log.signal     = NaN(tchain,length(x));
        p.psi.log.x          = NaN(tchain,length(x));
        p.psi.log.refface    = NaN(tchain,length(x));
        p.psi.log.testface   = NaN(tchain,length(x));
        p.psi.log.response   = NaN(tchain,length(x));
%         p.psi.log.xrounded   = NaN(p.stim.tFace/tchain+1,p.psi.presentation.numtrials_chain,tchain);
        p.psi.log.xrounded   = NaN(length(unique(x)),max(p.psi.presentation.rep),tchain);
        p.psi.log.sdt        = NaN(tchain,length(x));  
        p.psi.log.trial_counter  = zeros(length(unique(x)),tchain);
    end

    function SetLog
        
        p.psi.log.globaltrial(current_chain,cc(current_chain))= tt;
        p.psi.log.signal(current_chain,cc(current_chain))     = signal;
        p.psi.log.x(current_chain,cc(current_chain))          = x(cc(current_chain),current_chain);
        p.psi.log.refface(current_chain,cc(current_chain))    = ref_face;
        p.psi.log.testface(current_chain,cc(current_chain))   = test_face;
        p.psi.log.response(current_chain,cc(current_chain))   = response;
        p.psi.log.sdt(current_chain,cc(current_chain))        = sdt;%1=hit 2=FA 3=miss 4=CR
 
        
    end
%     function PlotProcedure
%         plotproc=figure(1);
%         %         title(sprintf('Threshold Estimation for subject %02d',tchain),'FontSize',14)
%         for sub=1:tchain;
%             subplot(2,2,sub)
%             t = 1:length(p.log.x(sub));
%             hold on;
%             plot(t,abs(p.log.x(sub)),'bo-');
%             errorbar(t,p.log.alpha(sub),p.log.seAlpha(sub),'r--')
%             plot(t(p.log.response(sub) == 1),p.log.x(sub)(p.log.response(sub) == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(p.log.response(sub) == 0),p.log.x(sub)(p.log.response(sub) == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(p.log{sub}.alpha)+max(p.log{sub}.seAlpha)+20])
%             xlabel('Trial');
%             ylabel('xCurrent (Deg)');
%             
%         end
%         annotation('textbox', [0 0.9 1 0.1], 'String',...
%             (sprintf('Threshold Estimation for subject %02d',tchain)), ...
%             'EdgeColor', 'none', ...
%             'HorizontalAlignment', 'center','FontSize',14)
%         legend('xCurrent','estimated Threshold','Response = 1','Response = 0','Location','northeast');
%       
% %     end
%     function Plot_Fit
%         plotfit=figure(2);
%          for sub=1:tchain;
%             subplot(2,2,sub)
%             t = 1:length(p.log{sub}.x);
%             hold on;
%             plot(t,abs(p.log{sub}.x),'bo-');
%             errorbar(t,p.log{1}.alpha,p.log{1}.seAlpha,'r--')
%             plot(t(p.log{sub}.response == 1),p.log{sub}.x(p.log{sub}.response == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(p.log{sub}.response == 0),p.log{sub}.x(p.log{sub}.response == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(p.log{sub}.alpha)+max(p.log{sub}.seAlpha)+20])
%             xlabel('Trial');
%             ylabel('xCurrent (Deg)');
%             
%         end

function [t]=StartEyelinkRecording(trialID,phase,cc,tt,current_chain,isref,file,delta_ref,delta_csp,abs_FGangle,fixx,fixy)
    
        t = [];
        
        
        Eyelink('Message', 'TRIALID:%04d, PHASE:%04d, CHAIN:%04d, CHAINTRIAL:%04d, TTRIAL:%04d, ISREF:%04d, FILE:%04d, DELTAREF:%04d, DELTACSP:%04d, FGDEG:%04d, FXX:%04d, FXY:%04d',trialID, phase,...
            current_chain, cc, tt, isref, file, delta_ref*100, delta_csp*100, abs_FGangle*100,fixx,fixy);
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(file,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %d, Phase: %d"',file, phase);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen
        Eyelink('ImageTransfer',p.stim.files24(file,:),p.ptb.imrect(1),p.ptb.imrect(2),p.ptb.imrect(3),p.ptb.imrect(4),p.ptb.imrect(1),p.ptb.imrect(2));        
        Eyelink('Command', 'draw_cross %d %d %d',p.ptb.midpoint(1),p.ptb.CrossPositionET_y(1),p.ptb.fc_size);        
        Eyelink('Command', 'draw_cross %d %d %d',p.ptb.midpoint(1),p.ptb.CrossPositionET_y(2),p.ptb.fc_size);
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
        %start recording following mode transition and a short pause.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('StartRecording');
        
        t = GetSecs;
        Log(t,8,NaN);
end

function [t] = StopEyelinkRecording
        
        Eyelink('Message', 'Stim Offset');            
        Eyelink('Message', 'BLANK_SCREEN');
        Eyelink('StopRecording');
        t = GetSecs;
        %this is the end of the trial scope.
        WaitSecs(0.01);
        Eyelink('Message', 'TRIAL_RESULT 0');
        %
        WaitSecs(0.01);
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('Command', 'clear_screen %d', 0);
        
        Log(t,-8,NaN);
end

function InitEyeLink
        %
        if EyelinkInit(0)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        %
        WaitSecs(0.5);
        [~, vs] = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );
        
        %load 24bits pictures for eyelink...
        dummy = dir([p.path.stim24 '*.bmp']);
        p.stim.files24    = [repmat([fileparts(p.path.stim24) filesep],length(dummy),1) vertcat(dummy(:).name)];
%         for i=1:32
%         filename       = p.stim.files24(nStim,:);
%                 [im , ~, ~]    = imread(filename);
%         end
%                           
        %
        el                          = EyelinkInitDefaults(p.ptb.w);
        %update the defaults of the eyelink tracker
        el.backgroundcolour         = p.stim.bg;
        el.msgfontcolour            = WhiteIndex(el.window);
        el.imgtitlecolour           = WhiteIndex(el.window);
        el.targetbeep               = 0;
        el.calibrationtargetcolour  = WhiteIndex(el.window);
        el.calibrationtargetsize    = 1.5;
        el.calibrationtargetwidth   = 0.5;
        el.displayCalResults        = 1;
        el.eyeimgsize               = 50;
        el.waitformodereadytime     = 25;%ms
        el.msgfont                  = 'Times New Roman';
        el.cal_target_beep          =  [0 0 0];%[1250 0.6 0.05];
        %shut all sounds off
        el.drift_correction_target_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        %PsychEyelinkDispatchCallback(el)
                            
        % open file.
        res = Eyelink('Openfile', p.path.edf);
        if res == -3
            fprintf('File cannot be created!!!!\n');
            return;
        end
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearCloud Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV5');
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'select_parser_configuration = 1');
        %what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);
    end
function StopEyelink(filename)
        try
            fprintf('Trying to stop the Eyelink system with StopEyelink\n');
            Eyelink('StopRecording');
            WaitSecs(0.5);
            Eyelink('Closefile');
            display('receiving the EDF file...');
            Eyelink('ReceiveFile',filename,[p.path.subject '\eye\'],1);
            display('...finished!')
            % Shutdown Eyelink:
            Eyelink('Shutdown');
        catch
            display('StopEyeLink routine didn''t really run well');
        end
    end
function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p.var.ExpPhase  = 0;
        ShowInstruction(0);
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s',messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
end

        

function Log(ptb_time, event_type, event_info)
        %Phases:
        %Pre-Experiment       :     1
        %Post-Experiment      :     2
%         %Instruction          :     1
%         %Baseline             :     2
%         %Conditioning         :     3
%         %Test                 :     4
%         %Rating               :     5
%         %Calibration          :     0
        %
        %event types are as follows:
        %
        %Scan Detection       :     0    info: NaN;
        %Cross Onset          :     1    info: position
        %Stimulus Onset/Offset:     2/-2 info: stim_id
        %Cross Movement       :     3    info: NaN;
        %Stimulus Offset      :     -2   info: NaN;
        %UCS Delivery         :     4    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Onset/Offset :     8    info: NaN;
        %
        %Text on the screen   :     5    info: Which Text?
        %RatingScreen Onset   :     6    info: NaN;
        
        p.var.event_count                = p.var.event_count + 1;
        p.out.log(p.var.event_count,:)   = [ptb_time event_type event_info phase];
        % %         p_out_log(p.out.event_counter,:)
        %logstring([ 'Logged: ' mat2str(p_out_log(p.out.event_counter,:)) ' - Type: ' p.verbose.eventtype{abs(event_type)} ' - Phase: ' p.verbose.eventphase{CurrentExperimentalPhase}])
        %for i = 1:3;subplot(3,1,i);plot(p_out_log(1:p.out.event_counter ,i),'o-');drawnow;end
        %
        
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
