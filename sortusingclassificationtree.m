function predctdata = sortusingclassificationtree(inputdata,prtclethrshold,prtcltree,noisetree)

% prtclethrshold = 5000;

if length(inputdata.majsiz) < prtclethrshold
    tree = noisetree;
else
    tree = prtcltree;
end

table = struct2table(inputdata);
index = predict(tree,table)== 'Particle_round';

fnames = fieldnames(inputdata);

for i=1:length(fnames)
    predctdata.(fnames{i}) = inputdata.(fnames{i})(index);
end

end