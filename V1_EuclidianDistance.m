function [ed] = V1_EuclidianDistance(imfolder)
%   Computes a similarity metric using V1 complex cell model used in Yue et
%   al, Vision Research 2012. So basically it is a wrapper around Yue's
%   function to analyze the faces we use. PATH2STIM can optionaly be used
%   to run the analysis on different faces tham the default set, in that
%   case PATH2STIM must be a string representing the path to the folder
%   containing the faces.
%


tImage = length(ListFiles(sprintf('%s*.mat',imfolder)));
%% compute a difference metric
ed = zeros(tImage);
r = [];
for nf1 = 1:tImage
    a = load(sprintf('%sV1_%02d.mat',imfolder,nf1));
    for nf2 = 1:tImage
        if nf2<nf1
            fprintf('Processing face %d-%d\n',nf1,nf2);            
            b = load(sprintf('%sV1_%02d.mat',imfolder,nf2));
            %
            ed(nf1,nf2) = norm(a.v1(:)-b.v1(:));
            ed(nf2,nf1) = ed(nf1,nf2);
        end
    end
end

%%
save(sprintf('%s%EuclidianDistances.mat',imfolder),'ed');
