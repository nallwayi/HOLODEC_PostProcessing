
#! /bin/bash
#
# BASH scriot to copy the contents of the RF files into sequences
#
#
  echo " This is a bash script to create symbolic link for the contents of the reconstructed flights into sequences of a minute data each"

 from=$(echo "/data/hulk/Susanne/RF14/recon")
 to=$(echo "/data/hulk/Nithin/RF14/data")
  
  
  function symboliclink(){
  
  for i in $(seq -w 08 12);do 
  #mkdir seq${i} 
   for j in $(seq -w 00 59);do
        input=$(echo "$1/ACEENA_RF14_2017-07-12-${i}-${j}-*.mat")
        mkdir -p $2/seqdata${i}/seq${j}
        output=$(echo "$2/seqdata${i}/seq${j}")
	if ls ${input} &>/dev/null;then
          ln -sf ${input} ${output}
	fi
    done
  done

    }

  export -f symboliclink

  symboliclink ${from} ${to}
