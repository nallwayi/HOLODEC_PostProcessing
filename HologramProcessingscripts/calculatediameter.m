function pd=calculatediameter(particledata)

    pd.eqdiameter  = particledata.eqsiz;
    pd.majdiameter = particledata.majsiz;
    pd.mndiameter = 0.5*(particledata.majsiz+particledata.minsiz);
    pd.holonum     = particledata.holonum;
    pd.holotimes   = particledata.holotimes;

end