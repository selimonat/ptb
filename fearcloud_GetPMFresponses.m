function [out]=fearcloud_GetPMFresponses(sub,run,chain,mod)
%Gets responses from the Discrimination Task for one subject, one run
%(before or after), one CS (CS+ or CS-), and allows to choose output
%format:
%MATRIX gives you the P_correct matrix with NaNs and 0 and 1, where rows
%are stimlevels and columns are trials
%P_CORRECT gives the percentage correct for stimlevels
%YES gives out.yes = number of yes
% out.num = number of trials it was asked
global project_path
project_path='C:\Users\onat\Google Drive\EthnoMaster\data\';

p=isn_GetData(sub,run,'stimulation');
p=p.p;
resp=p.psi.log.xrounded(:,:,chain);
if strcmp(mod,'matrix')
 out=resp;
elseif strcmp(mod,'p_correct')
 out=nanmean(resp,2);
elseif strcmp(mod,'yes')
   out=struct('yes',NaN(1,size(resp,1)),'num',NaN(1,size(resp,1)));
  for level=1:size(resp,1);
      if ~isnan(resp(level,1));
      out.yes(level)=sum(resp(level,~isnan(resp(level,:))));
      out.num(level)=length(resp(level,~isnan(resp(level,:))));
      end
  end
else 
    fprintf('Select correct Input : matrix, p_correct, or yes!')
    out=[];
end
end