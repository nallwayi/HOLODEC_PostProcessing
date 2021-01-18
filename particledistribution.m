% function particledistribution()

% input = pd;
input=particledata;
% input = finaldata;

input.xpos = input.xpos.*1e6;
input.ypos = input.ypos.*1e6;
input.zpos = input.zpos.*1e6;

binsize = 100;

x = -7220:binsize:7220;%*1e6;
y = -4810:binsize:4810;%*1e6;

% index{1:size(x,2)-1} = 0;

distribution = size(size(y,2)-1,size(x,2)-1);

    for i=1:size(x,2)-1        
        temp = find(input.xpos > x(i) & input.xpos <= x(i+1)); 
        index{1,i} = temp;
    end
        
    for i=1:size(y,2)-1
        temp = find(input.ypos > y(i) & input.ypos <= y(i+1)); 
         index{2,i} = temp;
    end   
    tt=[];
   for j= 1:size(y,2)-1
        for k=1:size(x,2)-1
            distribution(j,k)= numel(intersect(index{2,j},index{1,k}));
            if numel(intersect(index{2,j},index{1,k}))>22
                tt=[tt ;(intersect(index{2,j},index{1,k}))];
            end
        end         
   end
   
   % Verification
   no_particles = sum(sum(distribution));
   figure
   im=image(x*1e-3,y*1e-3,distribution);
   set(gca,'YDir','normal')
   im.CDataMapping = 'scaled';
   xlabel('x (mm)')
   ylabel('y (mm)')
   colorbar
   
   