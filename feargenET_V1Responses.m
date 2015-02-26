% find images
p2s   = '/Users/onat/Documents/EthoFaces_GrayScale/'
files = ListFiles(p2s);
cd(p2s)



%% load the images as a matrix [pixels x images]
stim = [];
v1   = [];
for nf = 1:32;    
    fprintf('Image: %03d\n',nf);
    im         = imread(files{nf});
    %take only the first channel
    stim(:,nf) = Vectorize(im(:,:,1));
    im         = imresize(im(:,:,1),[256 256]);
    v1(:,:,nf) = GWTWgrid_Simple(im,0,2);    
end
% average across filters
v1 = squeeze(mean(v1,2));
% removal of average...
v1 = v1 - repmat(mean(v1,2),[1 32]);
v1 = Scale(v1);

%% save the output images
p2w = '/Users/onat/Documents/EthoFaces_V1/';
mkdir(p2w);
for nf = 1:size(v1,2)
    dummy = imrotate(reshape(v1(:,nf),256,256),-90);
    imwrite(dummy,sprintf([p2w '%2d.bmp'],nf),'bmp');
end
%%
% average across within circles 
imwrite(imrotate(   reshape(mean(v1(:,1:16),2),256,256),-90),sprintf([p2w '%s.bmp'],'mean_locals'),'bmp')
imwrite(imrotate(   reshape(mean(v1(:,17:32),2),256,256),-90),sprintf([p2w '%s.bmp'],'mean_foreign'),'bmp')
% compute the diff within a circle 
imwrite(imrotate(reshape((mean(abs(diff(v1(:,[1:16 1]  ),1,2)),2)),256,256),-90),sprintf([p2w '%s.bmp'],'meandiff_locals'),'bmp')
imwrite(imrotate(reshape((mean(abs(diff(v1(:,[17:32 17]),1,2)),2)),256,256),-90),sprintf([p2w '%s.bmp'],'meandiff_foreigns'),'bmp')
% compute the diff between circles
imwrite(imrotate( reshape((mean( abs(v1(:,1:16) - v1(:,17:32)),2)),256,256),-90),sprintf([p2w '%s.bmp'],'mean_diff_between'),'bmp')


%%
[a,b,c,d] = GWTWgrid_Simple(pic2,0,2,4.2);
[vec,freq]=ReduceFFT2(d);
figure(1);
hold on;
plot(freq*36,vec,'k');
set(gca,'yscale','log','xscale','log','xtick',[.5 1 2 4 8 16]);xlim([0.5 16]);
figure(2);
imagesc(rot90(reshape(mean(a,2),256,256),-1));
colormap gray;
axis image;

