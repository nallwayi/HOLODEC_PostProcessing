
% Function to determine and eliminate ghost particles both from 3d and 2d
% distribtuions. The function also returns the 2d particle distribution


function [particledata,gpindex,numgp,dist2d,label] = findghostparticles(input)

    % Conversion to micro meters for ease of calculation

    input.xpos = input.xpos.*1e6;
    input.ypos = input.ypos.*1e6;
    input.zpos = input.zpos.*1e6;

    binsize = 100;

    x = -7250:binsize:7250;
    y = -4850:binsize:4850;
    z = 5000:10*binsize:170000;
    
    index = cell(3,length(z)-1);
    ind2 = cell(2,length(z)-1);
    holes = cell(2,length(z)-1);
    
    % 3d poisson statistics
    novox = 0.8*(length(x)-1)*(length(y)-1)*(length(z)-1);
    lambda = length(input.xpos)/novox;
    cnt3=1:round(4*lambda);
    P = lambda.^cnt3.*exp(-lambda)./factorial(cnt3);
    thresh3d = find(P*novox > 0.5, 1, 'last' )  
    tic
    for cnt=1:length(x)-1        
        temp = find(input.xpos > x(cnt) & input.xpos <= x(cnt+1)); 
        if temp >thresh3d
            index{1,cnt} = temp;
        end
            holes{1,cnt}=temp;     
    end
        
    for cnt=1:length(y)-1
        temp = find(input.ypos > y(cnt) & input.ypos <= y(cnt+1)); 
        if temp > thresh3d
            index{2,cnt} = temp;
        end
            holes{2,cnt}=temp;
        
    end        
   
    for cnt=1:length(z)-1
       temp = find(input.zpos > z(cnt) & input.zpos <= z(cnt+1)); 
        if temp > thresh3d
            index{3,cnt} = temp;
        end
    end
 
    numgp=0;   
    gpindex3d=[];
    for cnt = 1:size(z,2)-1
        cnt
        for cnt2= 1:size(y,2)-1
            temp= intersect(index{3,cnt},index{2,cnt2});
            for cnt3=1:size(x,2)-1
                gpcnt = intersect(temp,index{1,cnt3});        
                if numel(gpcnt) > thresh3d
                    gpindex3d =[gpindex3d;gpcnt];
                    numgp= numgp+1;
                end  
            end
        end
    end
    toc
   fnames = fieldnames(input);
   for cnt=1:length(fnames)
       input.(fnames{cnt})(gpindex3d)=[];
   end


    
   
   % 2d poisson statistics
   nopix = 0.8*(length(x)-1)*(length(y)-1);
   factor=1;
   lambda = length(input.xpos)/nopix;
   if lambda>100
       factor=100;
   lambda = length(input.xpos)/nopix/factor;
   end
   count=1:round(3*lambda);
   if lambda < 100
     P = lambda.^count.*exp(-lambda)./factorial(count);
   else
      mu = lambda;
      sigma = sqrt(lambda);
      P=1/(sigma*sqrt(2*pi))* exp(-0.5.*((count-mu)/sigma).^2);
   end
   
 
      
   thresh2d = find(P*nopix > 0.5, 1, 'last' )*factor 
   lowerthreshold=00;
   dist2d = size(size(y,2)-1,size(x,2)-1);
   dist2dfin = size(size(y,2)-1,size(x,2)-1);
   
   gpindex2d   =[];
   lowerindex=[];

    
       
   for cnt=1:size(x,2)-1        
        temp = find(input.xpos > x(cnt) & input.xpos <= x(cnt+1)); 
        if temp >0
            ind2{1,cnt} = temp;
        end
    end
        
    for cnt=1:size(y,2)-1
        temp = find(input.ypos > y(cnt) & input.ypos <= y(cnt+1)); 
        if temp >0
            ind2{2,cnt} = temp;
        end        
    end 
    
   
   for cnt2= 1:size(y,2)-1
        for cnt3=1:size(x,2)-1
            gpcnt = intersect(ind2{2,cnt2},ind2{1,cnt3});
            dist2d(cnt2,cnt3)= numel(gpcnt);
            
            if numel(gpcnt) > thresh2d
                 dist2dfin(cnt2,cnt3) = 0;
                 gpindex2d =[gpindex2d;gpcnt];
                 numgp=numgp+1;
            else
               dist2dfin(cnt2,cnt3) = dist2d(cnt2,cnt3);
            end
            if numel(gpcnt) < lowerthreshold
                lowerindex=[lowerindex;gpcnt];
            end
            
            
        end         
   end
   
     distarry = reshape(dist2d,1,[]);
     label=[];
%    Determining labels for volume calculation
     for cnt2=1:(length(x)-1)*(length(y)-1)
       if distarry(cnt2)>thresh2d || distarry(cnt2)<lowerthreshold
           label=[label;cnt2];
       end
     end
     

    figure
    hist(reshape(dist2dfin,1,[]),length(count))
    hold on
    plot(count*factor,P*nopix,'r')
    title('2D poisson distribution & Histogram of data')
    xlabel('Number of particles per pixel')
    ylabel('Count')
%     saveas(gcf,'Histfile.png')   


   
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
%    saveas(im,'2ddist_ini.png')  
   

    
    
    input.xpos = input.xpos.*1e-6;
    input.ypos = input.ypos.*1e-6;
    input.zpos = input.zpos.*1e-6;
    
   fnames = fieldnames(input);
   for cnt=1:length(fnames)
       input.(fnames{cnt})(union(gpindex2d,lowerindex))=[];
       particledata.(fnames{cnt}) = input.(fnames{cnt});
   end
   
   figure
   im=image(x*1e-3,y*1e-3,dist2dfin);
   set(gca,'YDir','normal')
   im.CDataMapping = 'scaled';
   title('2D particle number density without ghost particles')
   xlabel('x (mm)')
   ylabel('y (mm)')
   colorbar
%    saveas(im,'2ddist_fin.png')

   gpindex = union(gpindex3d,gpindex2d);
end

