function [thescenepath,thescene] = LoadStimuli(trial,thephase,phasei,thepart,parti,thecat,n,fileX,init)       

for pici = trial:trial-1+n.(thephase{phasei}).(thepart{parti}).t2b
    if fileX.(thephase{phasei}).(thepart{parti})(pici,6)<10
        thescenepath{pici} = fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['00',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp']);
    elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>9 && fileX.(thephase{phasei}).(thepart{parti})(pici,6)<100
        thescenepath{pici} = fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['0',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp']);
    elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>99
        thescenepath{pici} = fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),[num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp']);
    end
    thescene{pici} = uint8(imread(thescenepath{pici}));
end
