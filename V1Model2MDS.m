function [mds]=V1Model2MDS(ed,mds_dim)
%[mds]=V1Model2MDS(ed,mds_dim)
%
% Runs mds analysis with MDS_DIM dimensions on euclidian distances.


mds   = mdscale(ed,mds_dim,'criterion','metricstress'); %set to (im,2) for 2-dimensional scaling.
