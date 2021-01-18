
% Function to determine and eliminate ghost particles both from 3d and 2d
% distribtuions. The function also returns the 2d particle distribution

% Check with Dr. Shaw about the determination of threshold for removing
% particles in a 3d voxel and 2d pixel

function [particledata,gpindex,numgp,dist2d,label] = findghostparticles(sorteddata)

    % Conversion to micro meters for ease of calculation

    sorteddata.xpos = sorteddata.xpos.*1e6;
    sorteddata.ypos = sorteddata.ypos.*1e6;
    sorteddata.zpos = sorteddata.zpos.*1e6;

    binsize = 100;

    x = -7250:binsize:7250;
    y = -4850:binsize:4850;
    z = 5000:10*binsize:170000;
    
    index = cell(3,length(z)-1);
    ind2 = cell(2,length(z)-1);
    holes = cell(2,length(z)-1);
    
    % 3d poisson statistics
    novox = 0.8*(length(x)-1)*(length(y)-1)*(length(z)-1);
    lambda = length(sorteddata.xpos)/novox;
    k=1:round(4*lambda);
    P = lambda.^k.*exp(-lambda)./factorial(k);
    thresh3d = find(P*novox > 0.5, 1, 'last' )  
    
    for i=1:size(x,2)-1        
        temp = find(sorteddata.xpos > x(i) & sorteddata.xpos <= x(i+1)); 
        if temp >thresh3d
            index{1,i} = temp;
        end
            holes{1,i}=temp;
        

    end
        
    for i=1:size(y,2)-1
        temp = find(sorteddata.ypos > y(i) & sorteddata.ypos <= y(i+1)); 
        if temp > thresh3d
            index{2,i} = temp;
        end
            holes{2,i}=temp;
        
    end        
   
    for i=1:size(z,2)-1
       temp = find(sorteddata.zpos > z(i) & sorteddata.zpos <= z(i+1)); 
        if temp > thresh3d
            index{3,i} = temp;
        end
    end
 
    numgp=0;   
    gpindex3d=[];
    for i = 1:size(z,2)-1
        i
        for j= 1:size(y,2)-1
            temp= intersect(index{3,i},index{2,j});
            for k=1:size(x,2)-1
                gpcnt = intersect(temp,index{1,k});        
                if numel(gpcnt) > thresh3d
                    gpindex3d =[gpindex3d;gpcnt];
                    numgp= numgp+1;
                end  
            end
        end
    end
    
   fnames = fieldnames(sorteddata);
   for i=1:length(fnames)
       sorteddata.(fnames{i})(gpindex3d)=[];
   end


    
   
   % 2d poisson statistics
   nopix = 0.8*(length(x)-1)*(length(y)-1);
   factor=1;
   lambda = length(sorteddata.xpos)/nopix;
   if lambda>100
       factor=100;
   lambda = length(sorteddata.xpos)/nopix/factor;
   end
   count=1:round(3*lambda);
   if lambda < 100
     P = lambda.^count.*exp(-lambda)./factorial(count);
   else
      mu = lambda;
      sigma = sqrt(lambda);
      P=1/(sigma*sqrt(2*pi))* exp(-0.5.*((k-mu)/sigma).^2);
   end
   
 
      
   thresh2d = find(P*nopix > 0.5, 1, 'last' )*factor 
   lowerthreshold=00;
   dist2d = size(size(y,2)-1,size(x,2)-1);
   dist2dfin = size(size(y,2)-1,size(x,2)-1);
   
   gpindex2d   =[];
   lowerindex=[];

    
       
       for i=1:size(x,2)-1        
        temp = find(sorteddata.xpos > x(i) & sorteddata.xpos <= x(i+1)); 
        if temp >0
            ind2{1,i} = temp;
        end
    end
        
    for i=1:size(y,2)-1
        temp = find(sorteddata.ypos > y(i) & sorteddata.ypos <= y(i+1)); 
        if temp >0
            ind2{2,i} = temp;
        end        
    end 
    
   
   for j= 1:size(y,2)-1
        for k=1:size(x,2)-1
            gpcnt = intersect(ind2{2,j},ind2{1,k});
            dist2d(j,k)= numel(gpcnt);
            
            if numel(gpcnt) > thresh2d
                 dist2dfin(j,k) = 0;
                 gpindex2d =[gpindex2d;gpcnt];
                 numgp=numgp+1;
            else
               dist2dfin(j,k) = dist2d(j,k);
            end
            if numel(gpcnt) < lowerthreshold
                lowerindex=[lowerindex;gpcnt];
            end
            
            
        end         
   end
   
     distarry = reshape(dist2d,1,[]);
     label=[];
%    Determining labels for volume calculation
     for j=1:(length(x)-1)*(length(y)-1)
       if distarry(j)>thresh2d || distarry(j)<lowerthreshold
           label=[label;j];
       end
     end
     

    figure
   hist(reshape(dist2dfin,1,[]),length(count))
    hold on
    plot(count*factor,P*nopix,'r')
    title('2D poisson distribution & Histogram of data')
    xlabel('Number of particles per pixel')
    ylabel('Count')
    saveas(gcf,'Histfile.png')   


   
%    Saving the 2d distribution before removing ghostparticles
%    f = figure('visible','off');
   figure
   im=image(x*1e-3,y*1e-3,dist2d);
   set(gca,'YDir','normal')
   im.CDataMapping = 'scaled';
   title('2D particle number density with 2dghost particles')
   xlabel('x (mm)')
   ylabel('y (mm)')
   colorbar
   saveas(im,'2ddist_ini.png')  
   

    
    
     sorteddata.xpos = sorteddata.xpos.*1e-6;
    sorteddata.ypos = sorteddata.ypos.*1e-6;
    sorteddata.zpos = sorteddata.zpos.*1e-6;
    
   fnames = fieldnames(sorteddata);
   for i=1:length(fnames)
       sorteddata.(fnames{i})(union(gpindex2d,lowerindex))=[];
       particledata.(fnames{i}) = sorteddata.(fnames{i});
   end
   
   figure
   im=image(x*1e-3,y*1e-3,dist2dfin);
   set(gca,'YDir','normal')
   im.CDataMapping = 'scaled';
   title('2D particle number density without ghost particles')
   xlabel('x (mm)')
   ylabel('y (mm)')
   colorbar
   saveas(im,'2ddist_fin.png')

   gpindex = union(gpindex3d,gpindex2d);
end

