
%  Function to remove shattering effects
%  Initially it only involves chop-pff method but is to be later modified
%  to include throw-away, SV surgery and Particle repair methods 
function particledata = removeshattering(particledata,method)

if nargin<2
    method = 'chopoff';
elseif nargin<1 || nargin>2
    sprintf('Invalid number of inputs')
end


if isequal(method,'chopoff')
    index = particledata.zpos < 0.025 | particledata.zpos > 0.145;
    fnames = fieldnames(particledata);
    
    for i=1:length(fnames)
        particledata.(fnames{i})(index) = [];
    end
end


end
