function [ response] = ObserverResponseFunction(PFfit,aa,beta,gamma,lambda,x)
%Simulates an observer in a Psychometric Experiment.
% Responses are generated following a Psychometric Function (PF) with
% Threshold aa, Slope ss (Beta = 1/ss), Gamma and Lambda.
% The Function has the shape defined by PFfit, e.g. Cumulative Normal

%Evaluate the Function here

if PFfit([aa beta gamma lambda],x) >= rand(1);
    response = 1;
else
    response = 0;
end
% % lapse moment happening
% if rand(1) <= lambda
%     response = randsample([0 1],1);
%     
% end

end

