#!/bin/csh -f

cd /home/EDA/ic_projs/HW_ICS/veri/sim/build_case2

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/opt/synopsys/vcs_2022.06/T-2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

