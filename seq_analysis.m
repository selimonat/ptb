function seq_analysis(seq_index)
Q       = 10;%number of conditions
max_ent = log2(Q+1);
orders  = [1 2 3 4 5];
rr      = 0.5;%reiforcement rating
rep_vec = [ones(1,9)*2 1 1];
ms      = seq_SecondOrderBalancedSequence(rep_vec,1);
ttrial  = length(ms);

switch seq_index
    case 1
        %% simple random sequence
        ms = seq_SecondOrderBalancedSequence(rep_vec,1);
        ms = Shuffle(ms-1);
        %adapt to the paradigm        
    case 2
        %% msequence
        ms = [];
        for r = randsample(1:18,18);
            [ms]=[ms ; mseq2(11,2,[],r)];
        end
        ms = ms(1:ttrial);
         ms(setdiff(find(ms == 10),randsample(find(ms == 10),1))) = [];
         nucs = sum(ms == 4)*(rr./(1-rr));
         tucs = sum(ms == 9);
         ms(randsample(find(ms == 9),tucs-nucs)) = [];    
    case 3
        %% What we planned for Lea's fear cloud exp (with null events as ISIs)        
        [seq]       = seq_feargen_eyelab('tshort','constant',1);
        ms          = seq.cond_id;    
    case 4
        %% Kao's sequence  
        a = load('/Users/onat/Documents/Code/Matlab/ER-fMRI_toolbox_KaoMH/MO_design_562015-012.mat');
        ms = a.Out.bestList;
    case 5
        %% optseq
        [~,ms] = seq_optseq22dm('/Users/onat/Desktop/optseq/selim-001.par');
        ms = ms - 1;
end
plotit;

    function plotit
        figure;
        set(gcf,'position',[0 0 200 600]);
        subplot(3,1,1)
        plot(ms,'o-');title('sequence')
        ent = [];
        for order = orders;
            [ent(order) ent0 entmax] = calcent(ms,order);
        end
        subplot(3,1,2)
        bar([0 orders],2.^[ent0 ent]);hold on
        plot(xlim,2.^[entmax entmax]);hold off;
        title('entropies')
        %%
        e =[];
%         [e d] = calc_meffdet(ms,20);
        [e d] = calc_meffdet(ms,10,max(ms)-1,3);
        [tdetmat,teffmat,tmaxdet,tmaxeff] = tcurve(Q,10,length(ms));
        subplot(3,1,3)
        bar(e(1));hold on;
        plot(xlim,[tmaxeff tmaxeff]);hold off;
        title(sprintf('efficiency: %03d',round(e(1)./tmaxeff*100)))
        drawnow;
    end
end