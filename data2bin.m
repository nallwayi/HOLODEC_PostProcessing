% dividing into radius bins

function holodec = data2bin(pStats)

volume  = pStats.volume;
volume  = volume*1e-3;% Conversion of cm^3 to litres

diamArr = pStats.metrics.majsiz;
secondArr =  pStats.metrics.holosecond;
noHoloPerSec = pStats.noholograms;

% Removing all particles below 10 microns
secondArr(diamArr <10e-6) = [];
diamArr(diamArr <10e-6) = [];


diamArr   = diamArr * 1e6; % diameter in um 
second = pStats.holoinfo(1,4):pStats.holoinfo(end,4);

bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60 70 80 ...
    90 100 150 200 250 300 350 400 450 500 2000];

for cnt=1:numel(bin)-1
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
    
    binNames(cnt) = convertCharsToStrings(['C' num2str(ini) num2str(fin)]);
end


concMtrx = ones(numel(bin)-1,numel(second))*(-9999);
concL    = ones(1,numel(second))*(-9999);
for cnt = 1:numel(second)
    ind = secondArr == second(cnt);
    if sum(ind) > 0
        tmp = diamArr(ind);
        no_holograms = noHoloPerSec(noHoloPerSec(:,1)==second(cnt),2);
        for cnt2 =2 :numel(bin)-1
            tmpConcVar = ...
                sum(tmp > bin(cnt2) & tmp < bin(cnt2+1))/no_holograms/...
                volume/(bin(cnt2+1)-bin(cnt2));
            if ~isempty(tmpConcVar)
                concMtrx(cnt2,cnt) =tmpConcVar;
            else
                concMtrx(cnt2,cnt) = 0;
            end
            
        end
        concL(cnt) = numel(tmp)/no_holograms/volume;
    end
end

holodec.Second = second';
holodec.concL = concL';
for cnt=1:numel(bin)-1
    holodec.(binNames(cnt)) = concMtrx(cnt,:)'; 
end
 
end