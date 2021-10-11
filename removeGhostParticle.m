
%  Function to identifty and remove the ghost particles 

function [pStats] = removeGhostParticle(pStats)

global xsize ysize zsize xbin ybin zbin
noPrtcls = size(pStats.metrics.timestamp,1);

% Defiing the volume limits
x_llim = -7250e-6;
x_ulim = 7250e-6;
y_llim = -4850e-6;
y_ulim = 4850e-6;
z_llim = 25000e-6;
z_ulim = 145000e-6;


binsize = 100e-6;
xbin    = x_llim:binsize:x_ulim;
ybin    = y_llim:binsize:y_ulim;
zbin    = z_llim:binsize*10:z_ulim;

xsize   = length(xbin)-1;
ysize   = length(ybin)-1;
zsize   = length(zbin)-1;




% Function to remove the ghost particles using 3d-poisson statistics
[GP3dStats]=removeGhostParticlesUsing3dPoissonStats(pStats.metrics,noPrtcls);
% save('GP3dStats.mat','GP3dStats')


pStats.GP3dStats = GP3dStats;
plot3dGhostParticleStats(pStats.header,pStats.metrics,GP3dStats)

% Removing the particles identified as ghost particles
fnames = fieldnames(pStats.metrics); 
for cnt=1:length(fnames)
    pStats.metrics.(fnames{cnt})(GP3dStats.gp3dInd)=[];
end


% Function to remove the ghost particles using 2d-poisson statistics
[GP2dStats]=removeGhostParticlesUsing2dPoissonStats(pStats.metrics,noPrtcls);
% save('GP2dStats.mat','GP2dStats') 

pStats.GP2dStats = GP2dStats;
plot2dGhostParticleStats(pStats.header,pStats.metrics,GP2dStats)


% Removing the particles identified as ghost particles

fnames = fieldnames(pStats.metrics); 
for cnt=1:length(fnames)
    pStats.metrics.(fnames{cnt})(GP2dStats.gp2dInd)=[];
end


end

% -------------------------------------------------------------------------




%%


function [GP3dStats]=removeGhostParticlesUsing3dPoissonStats(metrics,noPrtcls)
        
 global xsize ysize zsize xbin ybin zbin
 
  
% 3d Poisson Statistics
GP3dStats.novox = 0.75*(xsize-1)*(ysize-1)*(zsize-1); % 90 percent 
GP3dStats.lambda3d = noPrtcls/GP3dStats.novox; % avg prtcle cnt per voxel
P_3dthresh = 1; % Threshold count for 3d stats

% Poisson distribution for the 3d avg lambda value
GP3dStats.x_poisson3d =1:round(5*GP3dStats.lambda3d);
GP3dStats.P_poisson3d = GP3dStats.lambda3d.^(GP3dStats.x_poisson3d).*...
    exp(-GP3dStats.lambda3d)./factorial(GP3dStats.x_poisson3d);

GP3dStats.thresh3d = find(GP3dStats.P_poisson3d*GP3dStats.novox > P_3dthresh,...
     1, 'last' ); %threshold for 3d stats  


for cnt = 1:xsize
    prtclesIndxPerXbin{cnt} = ...
        find(metrics.xpos > xbin(cnt) & metrics.xpos <= xbin(cnt+1));
end
for cnt= 1:ysize             
    prtclesIndxPerYbin{cnt} = ...
        find(metrics.ypos > ybin(cnt) & metrics.ypos <= ybin(cnt+1));
end
for cnt= 1:zsize 
	prtclesIndxPerZbin{cnt} = ...
        find(metrics.zpos > zbin(cnt) & metrics.zpos <= zbin(cnt+1));
end



GP3dStats.prtclesCntPerXYZbin = nan(xsize,ysize,zsize);
GP3dStats.gp3dInd=[];
noVoxRmd=0;
GP3dStats.voxRmd3dInd=[];

for cnt = 1:xsize 
    for cnt2= 1:ysize   
        prtclesIndxPerXYbintmp = intersect(prtclesIndxPerXbin{cnt}...
            ,prtclesIndxPerYbin{cnt2});
        for cnt3= 1:zsize 
%         prtclesIndxPerXYZbin{cnt+(cnt3-1)*zsize,cnt2}=...
%             intersect(prtclesIndxPerXYbintmp,prtclesIndxPerZbin{cnt3});        
%         tmp =numel(prtclesIndxPerXYZbin{cnt+(cnt3-1)*zsize,cnt2});
        tmp = intersect(prtclesIndxPerXYbintmp,prtclesIndxPerZbin{cnt3});
%         if tmp >0 
            GP3dStats.prtclesCntPerXYZbin(cnt,cnt2,cnt3)= numel(tmp);
            if numel(tmp) > GP3dStats.thresh3d
                GP3dStats.gp3dInd  = [GP3dStats.gp3dInd; tmp];
                noVoxRmd =  noVoxRmd+1;
                GP3dStats.voxRmd3dInd(noVoxRmd,:) = [xbin(cnt) ybin(cnt2)...
                    zbin(cnt3)];
            end
%         end
        end
    end
end

 
GP3dStats.arryPrtcle3Ddist=[];
for cnt=1:size(GP3dStats.prtclesCntPerXYZbin,3)
    GP3dStats.arryPrtcle3Ddist = [GP3dStats.arryPrtcle3Ddist;...
        GP3dStats.prtclesCntPerXYZbin(:,:,cnt)];
end
GP3dStats.arryPrtcle3Ddist = GP3dStats.arryPrtcle3Ddist(GP3dStats.arryPrtcle3Ddist~=0);
GP3dStats.arryPrtcle3Ddist = reshape(GP3dStats.arryPrtcle3Ddist',1,[]);
end

function plot3dGhostParticleStats(header,metrics,GP3dStats)

f=figure('Name','GP-Pos','units','normalized','outerposition',[0 0 1 1]);
if ~isempty(GP3dStats.gp3dInd)
    gp3dPos(:,1) = metrics.xpos(GP3dStats.gp3dInd)*1e3;
    gp3dPos(:,2) = metrics.ypos(GP3dStats.gp3dInd)*1e3; 
    gp3dPos(:,3) = metrics.zpos(GP3dStats.gp3dInd)*1e3;
    scatter3(gp3dPos(:,1),gp3dPos(:,2),gp3dPos(:,3),5,'filled')
end
title('Ghost Particles identified in the volume')
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
savefig([header '_gp3dpos.fig'])
close(f)

f=figure('Name','3D-Poisson','units','normalized','outerposition',[0 0 1 1]);
histogram(GP3dStats.arryPrtcle3Ddist,1:round(max(GP3dStats.arryPrtcle3Ddist)))
xlim([0, 100]);
hold on
plot(GP3dStats.x_poisson3d,GP3dStats.P_poisson3d*GP3dStats.novox)
hold off
title('3D poission statistics')
xlabel(' # of particles per voxel')
ylabel('# of voxels')

savefig([header '_gp3dhist.fig'])
close(f)
end

%% 

function [GP2dStats]=removeGhostParticlesUsing2dPoissonStats(metrics,noPrtcls)
        
global xsize ysize xbin ybin 

% 2d Poisson Statistics
GP2dStats.nopix = 0.75*(xsize-1)*(ysize-1); % 90 percent 
GP2dStats.lambda2d = noPrtcls/GP2dStats.nopix; % avg prtcle cnt per pixel
GP2dStats.factor = 1;
P_2dthresh = 1; % Threshold count for 2d stats

% Poisson distribution for the 2d avg lambda value



if GP2dStats.lambda2d>100
    GP2dStats.factor=100;
    GP2dStats.lambda2d = noPrtcls/ GP2dStats.nopix/ GP2dStats.factor;
end

GP2dStats.x_poisson2d =1:round(5*GP2dStats.lambda2d);
GP2dStats.P_poisson2d = GP2dStats.lambda2d.^(GP2dStats.x_poisson2d)...
    .*exp(-GP2dStats.lambda2d)./factorial(GP2dStats.x_poisson2d);

% mu = lambda2d;
% sigma = sqrt(lambda2d);
% P_poisson2d=1/(sigma*sqrt(2*pi))* exp(-0.5.*((x_poisson2d-mu)/sigma).^2);

GP2dStats.thresh2d = find(GP2dStats.P_poisson2d*GP2dStats.nopix > P_2dthresh...
    , 1, 'last' )*GP2dStats.factor; %threshold for 2d stats 



for cnt = 1:xsize 
    prtclesIndxPerXbin{cnt} = ...
        find(metrics.xpos > xbin(cnt) & metrics.xpos <= xbin(cnt+1));
end
for cnt= 1:ysize           
    prtclesIndxPerYbin{cnt} = ...
        find(metrics.ypos > ybin(cnt) & metrics.ypos <= ybin(cnt+1));
end


GP2dStats.prtclesCntPerXYbin = nan(xsize,ysize);
GP2dStats.gp2dInd = [];
noPixRmd= 0;
GP2dStats.pixRmd2dInd=[];

for cnt = 1:xsize 
    for cnt2= 1:ysize 
    	prtclesIndxPerXYbin = intersect(prtclesIndxPerXbin{cnt}...
            ,prtclesIndxPerYbin{cnt2});
        GP2dStats.prtclesCntPerXYbin(cnt,cnt2) = numel(prtclesIndxPerXYbin);
        if numel(prtclesIndxPerXYbin) >  GP2dStats.thresh2d
                GP2dStats.prtclesCntPerXYbin(cnt,cnt2) = nan;
                GP2dStats.gp2dInd  = [GP2dStats.gp2dInd; prtclesIndxPerXYbin];
                noPixRmd =  noPixRmd+1;
                GP2dStats.pixRmd2dInd(noPixRmd,:) = [xbin(cnt) ybin(cnt2)];
        end
    end
end


temp = sort(reshape(GP2dStats.prtclesCntPerXYbin',1,[]));
% temp2 = sum(temp==0);
% temp2/numel(temp)
% temp(temp==0)=[];
lwThrshld = ...
    temp(floor((sum(temp<(0.1*(GP2dStats.lambda2d*GP2dStats.factor)))/...
    numel(temp)+0.01)*length(temp)));

noHlsRmd= 0;
GP2dStats.hlsRmd2dInd=[];
for cnt = 1:xsize
    for cnt2 = 1:ysize
        if GP2dStats.prtclesCntPerXYbin(cnt,cnt2) < lwThrshld
            GP2dStats.prtclesCntPerXYbin(cnt,cnt2) = nan;
            noHlsRmd = noHlsRmd +1;
            GP2dStats.hlsRmd2dInd(noHlsRmd,:) = [xbin(cnt) ybin(cnt2)];
        end
    end
end

GP2dStats.arryPrtcle2Ddist = reshape(GP2dStats.prtclesCntPerXYbin',1,[]);
GP2dStats.arryPrtcle2Ddist = GP2dStats.arryPrtcle2Ddist(~isnan(GP2dStats.arryPrtcle2Ddist));
GP2dStats.lwThrshldHoles = lwThrshld;
end

function plot2dGhostParticleStats(header,metrics,GP2dStats)

global xbin ybin 


if ~isempty(GP2dStats.gp2dInd)
    gp2dPos(:,1) = metrics.xpos(GP2dStats.gp2dInd)*1e3;
    gp2dPos(:,2) = metrics.ypos(GP2dStats.gp2dInd)*1e3; 
    f=figure('Name','2D-Poisson','units','normalized','outerposition',[0 0 1 1]);
    scatter(gp2dPos(:,1),gp2dPos(:,2),10,'filled')
    xlim([-7.250 7.250])
    ylim([-4.750 4.750])
    title('2D Ghost Pixels')
    xlabel('x (mm)')
    ylabel('y (mm)')
    savefig([header '_gp2dpos.fig'])
    close(f)
end

f = figure('Name','2D-Poisson','units','normalized','outerposition',[0 0 1 1]);
histogram(GP2dStats.arryPrtcle2Ddist,round(numel(GP2dStats.x_poisson2d)/2))
hold on
plot(GP2dStats.x_poisson2d*GP2dStats.factor,GP2dStats.P_poisson2d*GP2dStats.nopix)
hold off
title('2D poission statistics')
xlabel(' # of particles per pixel')
ylabel('# of pixels')
savefig([header '_gp2dhist.fig'])
close(f)

f=figure('Name','2D-Dist','units','normalized','outerposition',[0 0 1 1]);
Img2d = pcolor(0.5*(xbin(1:end-1)+xbin(2:end))*1e3,...
    0.5*(ybin(1:end-1)+ybin(2:end))*1e3,GP2dStats.prtclesCntPerXYbin');
Img2d.EdgeColor = 'none';
title('2D distribution of particles')
xlabel('x (mm)')
ylabel('y (mm)')

savefig([header '_dist2d.fig'])
close(f)
end