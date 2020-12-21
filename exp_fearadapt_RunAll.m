subjectnumber = 12;  
%% 1
p= exp_fearadapt_painthreshold(subjectnumber,1);
PT = p.threshold.final.estimated;
%% 2
exp_fearadapt_discr(subjectnumber,1,PT);
%% 3
exp_fearadapt_makeindstim(subjectnumber);
%% 4
exp_fearadapt_main(subjectnumber,PT);