function [face_space]= GetFaceSpace

% face_space =[50 49 47 43 38 32 25 17 9 0 -9 -17 -25 -32 -38 -43 -47 -49 -50 -49 -47 -43 -38 -32 -25 -17 -9 0 9 17 25 32 38 43 47 49;...
%     0 -3 -7 -10 -13 -15 -17 -19 -20 -20 -20 -19 -17 -15 -13 -10 -7 -3 0 3 5 8 10 11 13 14 15 15 15 14 13 11 10 8 5 3]';
% face_space =[ 0 -3 -7 -10 -13 -15 -17 -19 -20 -20 -20 -19 -17 -15 -13 -10 -7 -3 0 3 5 8 10 11 13 14 15 15 15 14 13 11 10 8 5 3;...
%     50 49 47 43 38 32 25 17 9 0 -9 -17 -25 -32 -38 -43 -47 -49 -50 -49
%     -47 -43 -38 -32 -25 -17 -9 0 9 17 25 32 38 43 47 49]';
% Ellipse GenderR=30, IDr=18
% face_space=[18 17 13 7 0 -7 -13 -17 -18 -17 -13 -7 0 7 13 17;...
%     0 11 21 28 30 28 21 11 0 -11 -21 -28 -30 -28 -21 -11]';

% 
% 5 circles
if ispc
    face_space=textread('C:\Users\onat\Desktop\circle_calculation_txt.txt');
else
    face_space=textread('/Users/onat/Dropbox/feargen_lea/EthnoMaster/smoothingbusiness/5circles/circle_calculation_txt.txt');
end

face_space=face_space-repmat(mean(face_space),[size(face_space,1),1]);