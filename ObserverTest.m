

% set all the parameters for the Observer
aa=90;
sd=30;
beta=1/sd;
gamma=0.5;
lambda=0;
PFfit=@PAL_CumulativeNormal;

x=linspace(1,180,180);

response=NaN(length(x),1000);

nsim=10000;

% simulate nsim stimuli per intensity of x    

for xx=x
  
   for i=1:nsim
 
   response(xx,i)= ObserverResponseFunction(PFfit,aa,beta,gamma,lambda,xx);
   
   end
   

end
pcorrect=mean(response,2);
    
    
    figure
    plot(x,PFfit([aa beta gamma lambda],x),'r')
    hold on;
    plot(x,pcorrect(x),'bo')