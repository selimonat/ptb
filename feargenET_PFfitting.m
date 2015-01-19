function feargenET_PFfitting(   cs_plusindex)

p = [];
SetParams;

%Simulated observer's characteristics
PFsimul = @PAL_Gumbel;
trueParams = [0 2 0.5 0.01];

%Set up running fit procedure:

%% Define prior
alphas = linspace(0,90,400);
prior = PAL_pdfNormal(alphas,0,400); %Gaussian
%%
%Termination rule
stopcriterion = 'trials';
stoprule = 10;

%Function to be fitted during procedure
PFfit    = @PAL_Gumbel;    %Shape to be assumed
beta     = 2;               %Slope to be assumed
lambda   = 0.01;         %Lapse rate to be assumed
meanmode = 'mean';      %Use mean of posterior as placement rule

%set up procedure
RF = [];
face_ids = [1 5 9 13];
for nc = 1:4
RF{nc} = PAL_AMRF_setupRF('priorAlphaRange', alphas, 'prior', prior,...
    'stopcriterion',stopcriterion,'stoprule',stoprule,'beta',beta,...
    'lambda',lambda,'PF',PFfit,'meanmode',meanmode);
    RF{nc}.chain_faceid = face_ids(nc);
end
%need 4 PF, 1) cs+ local, 2)cs- local, 3) cs+ foreign, 4) cs-foreign
% random sequence of chains
chain_sequence = rand


%Trial loop
while RF{1}.stop ~= 1 && RF{2}.stop ~= 1 && RF{3}.stop ~= 1 && RF{4}.stop ~= 1
    
    current_chain = randsample(1:4,1);
    if RF{current_chain}.stop ~= 1
    %Present trial here at stimulus intensity UD.xCurrent and collect
    %response
    %Here we simulate a response instead (0: incorrect, 1: correct)    
    test_faceid  = RF.xCurrent;
    chain_faceid = RF{current_chain}.chain_faceid;
    %
    Trial(chain_faceid,test_faceid);
    
    response = rand(1) < PFsimul(trueParams,amplitude);    
    RF = PAL_AMRF_updateRF(RF, amplitude, response); %updating RF
    end
end



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
        Screen('Preference', 'SkipSyncTests', 1);
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
     
    end

function SetParams
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        p.path.baselocation  = 'C:\Users\onat\Documents\Experiments\';
        p.path.experiment    = [p.path.baselocation 'PainThreshold\'];
        %
        p.name              = subject;
        timestamp           = datestr(now,30);
        p.path.subject      = [p.path.experiment 'data\tmp\' p.name '_' timestamp '\'];
        p.path.finalsubject = [p.path.experiment 'data\' p.name '_' timestamp ];
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
        p.keys.confirm    = KbName('up');
        p.keys.increase   = KbName('right');
        p.keys.decrease   = KbName('left');
        p.keys.space      = KbName('space');
        p.keys.esc        = KbName('esc');
        %parallel port
        p.lpt.address = 888;
        p.lpt.US      = 255;
        p.lpt.shut  = 0;
        p.lpt.stim  = 1;
        p.lpt.fixation = 2;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        p.duration.shock           = 0.1;%s;x
        p.duration.shockpulse      = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse = 0.01;%ms; and the time between each pulse
        
        %
        %Save the stuff
        save(p.path.filename,'p');
end

end
