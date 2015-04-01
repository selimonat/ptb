function [ed] = V1_EuclidianDistance(imfolder)
% It computes a similarity matrix based on V1 responses.

tImage = length(ListFiles(sprintf('%sV1*.mat',imfolder)));
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
save(sprintf('%sEuclidianDistances.mat',imfolder),'ed');
