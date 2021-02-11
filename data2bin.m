% dividing into radius bins

function output = data2bin(pStats,volume)
tic
bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60 70 80 90 100 150 200 250 300 350 400 450 500 2000];
% bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60];
% 
diameter   = pStats.metrics.majsiz * 1e6; % diameter in um 
Second  = pStats.metrics.holosecond(1):pStats.metrics.holosecond(end);

volume  = volume*1e-3;% Conversion of cm^3 to litres
conc    = nan(length(Second),1);
concL   = nan(length(Second),1);

% Saving Time
output.Second=Second;

for cnt=1:length(bin)-1
    cnt
    ind1 = diameter > bin(cnt) & diameter < bin(cnt+1);
    if rem(bin(cnt),1)~=0
        ini = bin(cnt)*10;
        fin = bin(cnt+1);
    elseif rem(bin(cnt+1),1)~= 0
        ini = bin(cnt);
        fin = bin(cnt+1)*10;
    else
        ini = bin(cnt);
        fin = bin(cnt+1);
    end
    for cnt2=1:length(Second)
        
        ind2 = pStats.noholograms(:,1)==Second(cnt2);
        no_holograms = pStats.noholograms(ind2,2);
        
        if ~isempty(no_holograms)
            conc(cnt2) = sum(pStats.metrics.holosecond(ind1)==Second(cnt2))...
                /no_holograms/volume/(bin(cnt+1)-bin(cnt));
        end
    end
    
%   Saving concentrations  
    output.(['C' num2str(ini) num2str(fin)]) = conc;
end

for cnt2=1:length(Second)    
    ind2 = pStats.noholograms(:,1)==Second(cnt2);
    no_holograms = pStats.noholograms(ind2,2);

        if ~isempty(no_holograms)
            concL(cnt2) = sum(pStats.metrics.holosecond==Second(cnt2))...
                /no_holograms/volume;    
        end
end
% Saving Concentrations
output.concL = concL;
 
toc   
end