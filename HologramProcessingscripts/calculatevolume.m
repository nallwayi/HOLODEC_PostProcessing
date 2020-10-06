
% Function to calcuate the effective volume of a sequence of data, if the
% number of particles in a sequence is too low then the default parameters
% are used. Default parameters are initially defined manually
%  This funciton is onlt for the shattering effects removed by chop off
%  method. Other methods required modification of the function especially
%  to adujust the z position of the sample volume
%  The returned volume is in cm^3

function [area2dvar,volume]=calculatevolume(data,label)

% Default parameters
% data=particledata;
% Sequence specific parameters

% zpos = (0:0.1:15)*1e-2;

zini   = 25*1e3;
zfin   = 145*1e3;    
binsize = 100;
zpos = zini:binsize*10:zfin;
d2nebin = 0.1;
d2ne = (0:d2nebin:4.8)*1e3 ;

dist = zeros(size(d2ne,2)-1,size(zpos,2)-1);

 

for i=1:size(zpos,2)-1        
    temp = find(data.zpos*1e6 > zpos(i) & data.zpos*1e6 <= zpos(i+1)); 
    count{1,i} = temp;
end
for i=1:size(d2ne,2)-1        
    temp = find(data.d2ne*1e6 > d2ne(i) & data.d2ne*1e6 <= d2ne(i+1)); 
    count{2,i} = temp;
end

   for j= 1:size(d2ne,2)-1
        for k=1:size(zpos,2)-1   
            dist(j,k)= numel(intersect(count{2,j},count{1,k}));         
        end      
        divfac = (4850*2+7250*2-4*d2ne(j))/(4850*2+7250*2-4*d2ne(end));%Perimeter division
        dist(j,:) = dist(j,:)/divfac;
   end
   normftr = max(max(dist(40:48,1:10))); % normalizind factor;
   dist = dist./normftr;
%    assignin('base','dist',dist)
   

%     To create label for an area cross section

    xpos = -7250:binsize:7250;
    ypos = -4850:binsize:4850; 
    area2dlabel = zeros(3,(length(xpos)-1)*(length(ypos)-1));
    area2dlabel(1,:) = 1:(length(xpos)-1)*(length(ypos)-1);
    
    in = 1;
    fi = length(ypos)-1;
    for i=1:length(xpos)-1
        area2dlabel(2,in:fi)=xpos(i);
        area2dlabel(3,in:fi)=ypos(1:end-1);
        in = in + length(ypos)-1;
        fi = fi + length(ypos)-1;
    end
    
    
    
%    Determination the 75 percent cutoff
    y = zeros(1,length(zpos)-1);
    for i=1:length(zpos)-1
%         temp=d2ne(find(dist(:,i)>0.6, 1 ) -1);
%         if ~isempty(temp)
             y(i) = d2ne(find(dist(:,i)>0.75, 1 ) -1);
%         else
%             y(i)=nan;
%         end
%        find(dist(:,i)>0.75, 1 )-1;
%        dist(1:(find(dist(:,i)<0.75) -1),i) = 0;
%        index = find(data.d2ne<y(i) & data.zpos >zpos(i) & data.zpos < zpos(i+1));
    end
    
%     Fitting the points to generate the line of cut off
    line = polyfit((0.5*(zpos(1:end-1)+zpos(2:end))),y,1);
    m = line(1);
    c = line(2);
    fittedline = m.*(0.5*(zpos(1:end-1)+zpos(2:end)))+c;
    
%     Determining the new distribution and index of removed particles  
    index=[];
    cutoff = zeros(length(zpos)-1,1);
    for i=1:length(zpos)-1
        i
        cutoff(i) = round((find(d2ne>=fittedline(i),1)-1)*d2nebin*1e3);
        dist(1:(find(d2ne>=fittedline(i),1)-1),i) = 0; 
        index= [index;find(data.d2ne<fittedline(i) & data.zpos >zpos(i) & data.zpos < zpos(i+1))];
        xvar = -7250+cutoff(i):binsize:7250-cutoff(i);
        yvar = -4850+cutoff(i):binsize:4850-cutoff(i);
        area2dvar{i} = zeros(3,(length(xvar)-1)*(length(yvar)-1));
        
%         area2dvar{i}(1,:) = 1:(length(xpos)-1)*(length(ypos)-1);

    
        in = 1;
        fi = length(yvar)-1;
        for j=1:(length(xvar)-1)
            area2dvar{i}(2,in:fi)=xvar(j);
            area2dvar{i}(3,in:fi)=yvar(1:end-1);
%             area2dvar{i}(1,j) = area2dlabel(1,area2dvar{i}(2,j)== area2dlabel(2,:) & ...
%             area2dvar{i}(3,j)== area2dlabel(3,:)) ;
%         xvar(1)
%         yvar(1)
%         find(area2dvar{i}(2,j)== area2dlabel(2,:)& ...
%             area2dvar{i}(3,j)== area2dlabel(3,:)) 
            in = in + length(yvar)-1;
            fi = fi + length(yvar)-1;
        end
        for j=1:(length(xvar)-1)*(length(yvar)-1)
%             find(area2dvar{i}(2,j)== area2dlabel(2,:) & ...
%             area2dvar{i}(3,j)== area2dlabel(3,:))
            area2dvar{i}(1,j) = area2dlabel(1,find(area2dvar{i}(2,j)== area2dlabel(2,:) & ...
            area2dvar{i}(3,j)== area2dlabel(3,:))); 
        end
        vlmcnt(i) = length(area2dvar{i})-numel(intersect(label,area2dvar{i}(1,:)));
        tt= intersect(label,area2dvar{i}(1,:));        
        for j=1:length(tt)
        area2dvar{i}(:,area2dvar{i}(1,:)==tt(j))=[]; 
        end
    end

%     Removing the particles beyond the sample volume
    fnames = fieldnames(data);
    for i=1:length(fnames)
        data.(fnames{i})(index) = [];
    end
    
%     Finding the label of the volume slices

   volume=sum(vlmcnt)*1e7*1e-12;% cm^3
   figure('visible','on');
   im = image(zpos*1e-4,d2ne*1e-4,dist);
   im.CDataMapping = 'scaled';
   set(gca,'YDir','reverse')
   xlabel('zpos(cm)')
   ylabel('d2ne(cm)')
   colorbar
   hold on
   plot(0.5*1e-4*(zpos(1:end-1)+zpos(2:end)),y*1e-4,'xr')
   hold on
   plot(0.5*1e-4*(zpos(1:end-1)+zpos(2:end)),fittedline*1e-4,'w')
   saveas(im,'d2ne.png')
  
    
    
end
