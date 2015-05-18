function [s]=seq_optseq22s(filename)
%seq_optseq22s(filename)
%
%   Reads the opt2 sequence from FILENAME and returns a sequence vector.

%read the optseq
[time s  c d e] = textread(filename,'%f%f%s%s%s','delimiter','\t');
