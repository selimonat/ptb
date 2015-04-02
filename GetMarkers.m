path2sub = 'C:\Users\onat\Documents\Experiments\FearGeneralization\data\sub_001\';
data     = load([path2sub 'data\scr.mat']);
load([path2sub 'data\param.mat']);

%deduce the recorded patterns.
cs_cycle       = p.duration.shockpulse + p.duration.intershockpulse;
cs_duration    = p.duration.shock;
pattern_ucs    = [ 0 repmat([ ones(1,p.duration.shockpulse/data.isi) zeros(1,p.duration.intershockpulse/data.isi) ],1,floor(cs_duration./cs_cycle) ).*5 0];
pattern_stim   = [ 0 ones(1,p.duration.stimmarker/data.isi).*5 0];
%make a correlation with the pattern and the event channel.
i_ucs          = (conv(data.data(:,2),pattern_ucs./sum(pattern_ucs.^2),'same'));
i_stim         = (conv(data.data(:,2),pattern_stim./sum(pattern_stim.^2),'same'));
%these are the time points where UCS and STIM events occur.
t_ucs          = find(i_ucs > 0.9);
t_stim         = find(i_stim > 0.9);
%
%Produce the DESIGN MATRIX;%This could be computed in the Experiment
%Program
tCond          = length(unique(p.ri));
DM             = logical(zeros(size(data.data,1),tCond+1));%+1 becoz the UCS is the 13th condition
for nCond = 1:tCond    
   i                   = (p.ri == nCond) & (p.cs_plusevents == 0) & (p.expphase > 2);
   %discard the event which preceeds the UCS delivery
   %discard also the baseline phase of the experiment.
   DM(t_stim(i),nCond) = 1;
end
DM(t_ucs,tCond+1) =1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PLOT THE WHOLE DATA
figure;
set(gcf,'position',[6 742 1822 373])
hold off
time          = ((data.start_sample:(size(data.data,1)-1))*data.isi)./1000;
plot(time,data.data(:,1));
xlabel('time (s)')
ylabel(['SCR amplitude (' data.units(1,:) ')']);
hold on;
linesize = 0.2;
for nCond = 1:size(DM,2)
    if nCond < 13
        i = find(DM(:,nCond));
        plot([time(i) ;time(i)] , [(data.data(i,1)-linesize) (data.data(i,1)+linesize)]','-','color',hsv2rgb([(nCond-1)./12 1 1 ]),'linewidth',2);
    else
        i = find(DM(:,nCond));
        plot( time(i) , data.data(i,1) , 'k*' , 'linewidth', 1);
    end
end

SaveFigure([path2sub 'figures\RawData.eps'],'resolution',600);
SaveFigure([path2sub 'figures\RawData.png'],'resolution',600);
saveas(gcf,[path2sub 'figures\RawData'],'fig')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MAKE EVENT TRIGGERED AVERAGES
%map the condition indices to angles
phase = (pi/2:-pi/6:(-4*pi/3));
%polar plot parameters:
w = 0.1;h=w;%size of each single subplot
dia = (1-2*w)/2-0.1;%the diameter of the plot circle
%
%interval of data to be plotted
win  = 2000;%win is in samples, x5 gives the time in ms
time = (0:win)*data.isi/1000
%
figure;
set(gcf,'position',[767 161 1001 942]);
hold off
for nCond = 1:13;
    %
    counter    = 0;
    signal     = [];
    trial      = find(DM(:,nCond))';
    %trial are sample indices
    %
    for t = trial        
        counter  = counter + 1;
        dummy    = data.data(t:(t+win),1);
        dummy    = dummy - mean(dummy(1:500));
        signal(:,counter) = dummy;           
    end
    if nCond < 13%response to faces
        subplot('position',[cos(phase(nCond))*dia+0.5-w/2 sin(phase(nCond))*dia+0.5-h/2 w h])
        plot(time,mean(signal,2),'color',hsv2rgb([(nCond-1)./12 1 1 ]),'linewidth',2)
        box off     
        title(mat2str(nCond));
    else%response to the UCS
        subplot('position',[0.5-w/2 0.5-h/2 w h])
        plot(time,mean(signal,2),'color',hsv2rgb([(nCond-1)./12 1 1 ]),'linewidth',2)
        box off     
        title('UCS')
    end
    if nCond == 1
    xlabel('(s)')
    ylabel(['SCR']);
    end
end
SaveFigure([path2sub 'figures\ETA_polar.eps'],'resolution',600);
SaveFigure([path2sub 'figures\ETA_polar.png'],'resolution',600);
saveas(gcf,[path2sub 'figures\ETA_polar'],'fig')
