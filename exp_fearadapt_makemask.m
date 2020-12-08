function exp_fearadapt_makemask
p.path.baselocation       = 'U:\kampermann\';
p.path.experiment             = [p.path.baselocation 'FearAdapt_Pilote\'];
p.path.stim                   = [p.path.experiment 'discr_stim\'];
dummy = dir([p.path.stim '*.png']);
dummy = dummy([5:9,1:4,14:18,10:13]); %quick and dirty permutation so that filename row corresponds to cond_id.
p.stim.files    = [repmat([fileparts(p.path.stim) filesep],length(dummy),1) vertcat(dummy(:).name)];
p.stim.label = {dummy(:).name};

        p.stim.tFile                  = size(p.stim.files,1);%number of different files
for nStim = 1:p.stim.tFile
    filename       = p.stim.files(nStim,:);
    [im , ~, ~]    = imread(filename);
    if nStim<p.stim.tFile %this excludes the mask
        im = CenterStarfish(im);
    end
    
    %make the mask
    %             im_rect = %get the rect in which the actual starfish is
    star_roi  =CenterRectOnPointd([0 0 600 800], 900/2,1200/2);
    clipped   = im(star_roi(1)+1:star_roi(3),star_roi(2)+1:star_roi(4),:);
    im_mask = ScrambleImage(clipped);
    im_mask_full = im;
    im_mask_full(star_roi(1)+1:star_roi(3),star_roi(2)+1:star_roi(4),:)=im_mask;
    fname = ['mask_' filename];%strrep(filename,'.png','_mask.png');
    cd(p.path.stim)
    q=figure;
    imagesc(im_mask_full)
    axis image
    axis off
    print(q,fname,'-dpng');
    close all
end

    function scramble = ScrambleImage(im0)
        %as done in Norbury et al. 2018
        
        blockSize = 1;
        
        nRows = size(im0, 1) / blockSize;
        nCols = size(im0, 2) / blockSize;
        scramble = mat2cell(im0, ones(1, nRows) * blockSize, ones(1, nCols) * blockSize, size(im0, 3));
        scramble = cell2mat(reshape(scramble(randperm(nRows * nCols)), nRows, nCols));
        
        %save as desired
    end

    function centerput = CenterStarfish(imput)
        Nrows = size(imput,1); %this is x
        Ncols = size(imput,2); %this is y
        offset_x = 15; %this was determined via entering the clicking world.
        offset_y = 10;
        centerput = imput([(Nrows-offset_y):Nrows 1:(Nrows-offset_y-1)],[(offset_x+1):Ncols 1:offset_x],:);
    end
end