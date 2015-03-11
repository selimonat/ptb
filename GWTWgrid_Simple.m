function [JetsMagnitude, JetsPhase, GridPosition, Spectrum] = GWTWgrid_Simple(Im,ComplexOrSimple,GridSize,Sigma)

%
% The goal of this function is to transform a image with gabor wavelet
% method, and then convultion values at limited positions of the image
% will be choosed as output
%
% Usage: [JetsMagnitude, JetsPhase, GridPosition] = GWTWgrid_Simple(Im,ComplexOrSimple,GridSize,Sigma)
%
% Inputs to the function:
%   Im                  -- The image you want to reconstruct with this function
%
%   ComplexOrSimple     -- If input is 0, the JetsMagnitude would be complex cell responses (40 values) (default)
%                          If input is 1, the JetsMagnitude would be simple cell responses (80 values)
%
%   GridSize            -- If input is 0, grid size is 10*10 (default);
%                          If input is 1, grid size is 12*12 ;
%                          If input is 2, grid size would be the image size (128*128 or 256*256)
%
%   Sigma               -- control the size of gaussion envelope
%
%
% Outputs of the functions:
%   JetsMagnitude       -- Gabor wavelet transform magnitude
%   JetsPhase           -- Gabor wavelet transform phase
%   GridPosition        -- postions sampled
%   Spectrum            -- sums of all passed frequency information
%
% Created by Xiaomin Yue at 7/25/2004
%
% Last updated: 12/24/2004
%

if nargin < 1
    disp('Please input the image you want to do gabor wavelet transform.');
    return;
end

if nargin < 2
    ComplexOrSimple = 0;
    GridSize = 0;
    Sigma = 2*pi;
end

if nargin < 3
    GridSize = 0;
    Sigma = 2*pi;
end

if nargin < 4
    Sigma = 2*pi;
end

%% FFT of the image
Im = double(Im);
ImFreq = fft2(Im);
[SizeX,SizeY] = size(Im);
if (SizeX~=SizeY)
    disp('The image has to be squared. Please try again');
    return;
end

%% generate the grid
if SizeX==256
    if GridSize == 0
        RangeXY = 40:20:220;
    elseif GridSize == 1
        RangeXY = 20:20:240;
    else
        RangeXY = 1:256;
    end    
    [xx,yy] = meshgrid(RangeXY,RangeXY);
    Grid = xx + yy*i;
    Grid = Grid(:);
elseif SizeX==128
    if GridSize == 0
        RangeXY = 20:10:110;
    elseif GridSize == 1;
        RangeXY = 10:10:120;
    else
        RangeXY = 1:128;
    end    
    [xx,yy] = meshgrid(RangeXY,RangeXY);
    Grid = xx + yy*i;
    Grid = Grid(:);
elseif SizeX == 400
    RangeXY = 1:400;
    [xx,yy] = meshgrid(RangeXY,RangeXY);
    Grid    = xx + yy*i;
    Grid    = Grid(:);
else
    disp('The image has to be 256*256 or 128*128. Please try again');
    return;
end
GridPosition = [imag(Grid) real(Grid)];

%% setup the paramers
nScale       = 5; %15
nOrientation = 8;
xyResL       = SizeX; 
xHalfResL = SizeX/2; 
yHalfResL = SizeY/2;
kxFactor = 2*pi/xyResL;
kyFactor = 2*pi/xyResL;

%% setup space coordinate 
[tx,ty] = meshgrid(-xHalfResL:xHalfResL-1,-yHalfResL:yHalfResL-1);        
tx = kxFactor*tx;
ty = kyFactor*(-ty);

%% initiallize useful variables
if ComplexOrSimple == 0
    JetsMagnitude  = zeros(length(Grid),nScale*nOrientation);
    JetsPhase      = zeros(length(Grid),nScale*nOrientation);
else
    JetsMagnitude  = zeros(length(Grid),2*nScale*nOrientation);
    JetsPhase      = zeros(length(Grid),nScale*nOrientation);
end
Spectrum = zeros(SizeX);
for LevelL = 0:nScale-1
    k0 = (pi/2)*(1/sqrt(2)).^LevelL;
    for DirecL = 0:nOrientation-1
        kA = pi*DirecL/nOrientation;
        k0X = k0*cos(kA);
        k0Y = k0*sin(kA);
        %% generate a kernel specified scale and orientation, which has DC on the center
        FreqKernel = 2*pi*(exp(-(Sigma/k0)^2/2*((k0X-tx).^2+(k0Y-ty).^2))-exp(-(Sigma/k0)^2/2*(k0^2+tx.^2+ty.^2)));
        %% use fftshift to change DC to the corners
        FreqKernel = fftshift(FreqKernel);
        Spectrum   = Spectrum + fftshift(FreqKernel);        
        %% convolute the image with a kernel specified scale and orientation
        TmpFilterImage = ImFreq.*FreqKernel;
        %% calculate magnitude and phase
        if ComplexOrSimple == 0
            TmpGWTMag   = abs(ifft2(TmpFilterImage));
            TmpGWTPhase = angle(ifft2(TmpFilterImage));
            %% get magnitude and phase at specific positions
            tmpMag = TmpGWTMag(RangeXY,RangeXY);
            tmpMag = (tmpMag');
            JetsMagnitude(:,LevelL*nOrientation+DirecL+1)=tmpMag(:);
            tmpPhase = TmpGWTPhase(RangeXY,RangeXY);
            tmpPhase = (tmpPhase')+ pi;
            JetsPhase(:,LevelL*nOrientation+DirecL+1)=tmpPhase(:);
        else
            TmpGWTMag_real = (real(ifft2(TmpFilterImage)));
            TmpGWTMag_imag = (imag(ifft2(TmpFilterImage)));
            TmpGWTPhase = angle(ifft2(TmpFilterImage));
            %% get magnitude and phase at specific positions
            tmpMag_real = TmpGWTMag_real(RangeXY,RangeXY);
            tmpMag_real = (tmpMag_real');
            tmpMag_imag = TmpGWTMag_imag(RangeXY,RangeXY);
            tmpMag_imag = (tmpMag_imag');
            JetsMagnitude_real(:,LevelL*nOrientation+DirecL+1) = tmpMag_real(:);
            JetsMagnitude_imag(:,LevelL*nOrientation+DirecL+1) =  tmpMag_imag(:);
            tmpPhase = TmpGWTPhase(RangeXY,RangeXY);
            tmpPhase = (tmpPhase')+ pi;
            JetsPhase(:,LevelL*nOrientation+DirecL+1)=tmpPhase(:);            
        end    
    end
end    

if ComplexOrSimple ~=0
    JetsMagnitude = [JetsMagnitude_real JetsMagnitude_imag];
end


