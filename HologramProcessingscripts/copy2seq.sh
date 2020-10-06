#! /bin/bash
#
# BASH script to copy the contents of the RF files into sequences
#
#
  echo " This is a bash script to copy the contents of the reconstructed flights into sequences of a minute daata each"

  from=$(echo "/data/hulk/Nithin/RF18/recon")
  to=$(echo "/data/hulk/Nithin/RF18/data")

  
  function copy2seq(){
  
  for i in $(seq -w 08 12);do 
  #mkdir seq${i} 
   for j in $(seq -w 00 59);do
        input=$(echo "$1/ACEENA_RF18_2017-07-18-${i}-${j}-*.mat")
        mkdir -p $2/seqdata${i}/seq${j}
        output=$(echo "$2/seqdata${i}/seq${j}")
        mv ${input} ${output}
    done
  done

    }

  export -f copy2seq

  copy2seq ${from} ${to}

