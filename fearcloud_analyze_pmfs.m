global project_path
project_path='C:\Users\onat\Google Drive\EthnoMaster\data\'

subjects=[6:26,28:36];%PMF
%subjects to exclude bc of bad fitting:
%subexcl=6,8,9,18,21,22,23,28,29
subjects=[7,10,11:17,19:20,24:26,30,31,34:35];
subjects_eye=[6:26,28:36];
%subjects slower vs faster version
subjects_1500=[6:26,28:36];
subjects_600=[27,39,41:51];
%37 and 38 have smaller stimranges...

pmf=isn_getPMF(subjects,[1 5]);
% % %alternatively load them (this is the file with all subjects for Lea's Masterthesis):
% % pmf=load('C:\Users\onat\Google Drive\EthnoMaster\pmfmaster.mat');
% % pmf=pmf.pmf;

n=length(subjects);

betaSD=10.^-pmf.beta;
%compute the means and stds 
alpha.mean=mean(pmf.alpha);
alpha.std=std(pmf.alpha);
alpha.sem=alpha.std/sqrt(n);
beta.mean=mean(pmf.beta);
beta.std=std(pmf.beta);
beta.sem=beta.std/sqrt(n);
gamma.mean=mean(pmf.gamma);
lambda.mean=mean(pmf.lambda);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% statistical tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[p_csp_alpha,h,stats]=signtest(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[p_csn_alpha,h,stats]=signtest(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[p_csp_beta,h,stats]=signtest(pmf.beta(:,1,1),pmf.beta(:,1,2))
[p_csn_beta,h,stats]=signtest(pmf.beta(:,2,1),pmf.beta(:,2,2))

[p_csp_alpha,h]=signrank(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[p_csn_alpha,h]=signrank(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[p_csp_beta,h]=signrank(pmf.beta(:,1,1),pmf.beta(:,1,2))
[p_csn_beta,h]=signrank(pmf.beta(:,2,1),pmf.beta(:,2,2))

[h,p_csp_alpha]=ttest(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[h,p_csn_alpha]=ttest(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[h,p_csp_beta]=ttest(pmf.beta(:,1,1),pmf.beta(:,1,2))
[h,p_csp_beta]=ttest(pmf.beta(:,2,1),pmf.beta(:,2,2))

alph=[pmf.alpha(:,1,1),pmf.alpha(:,2,1);pmf.alpha(:,1,2),pmf.alpha(:,2,2)];
beta=[pmf.beta(:,1,1),pmf.beta(:,2,1);pmf.beta(:,1,2),pmf.beta(:,2,2)]
[p_a,table,stats]=anova2(alph,n);
[p_b,table,stats]=anova2(beta,n);


%%%%%%%%%%%%%%%GAUSS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[o]=fearcloud_fitgauss(subjects,[3 4])
sigma_cond=o.sigma(:,1);
sigma_test=o.sigma(:,2);
pmf.alpha(18,:,:)=[];
pmf.beta(18,:,:)=[];
alpha_before=mean(pmf.alpha(:,:,1),2);
beta_before=10.^-mean(pmf.beta(:,:,1),2);
diff_a_csp = pmf.alpha(:,1,1)-pmf.alpha(:,1,2);
diff_b_csp=pmf.beta(:,1,1)-pmf.beta(:,1,2);
SI=sigma_cond-sigma_test;


[rho, pval] = corr([alpha_before,beta_before,diff_a_csp,diff_b_csp,sigma_cond,sigma_test,SI], 'rows','pairwise')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%correlation between performance before, and diff
%%%%%%%%%%%%%%%%%%%%%%%%%%%
diff_b=10.^-pmf.beta(:,1,1)-10.^-pmf.beta(:,1,2);
%csminus
diff_bm=10.^-pmf.beta(:,2,1)-10.^-pmf.beta(:,2,2);
[r,p]=corr([diff_b,10.^-pmf.beta(:,1,1)],'rows','pairwise')
[r,p]=corr([diff_bm,10.^-pmf.beta(:,2,1)],'rows','pairwise')


