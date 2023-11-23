#!/bin/bash
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=daisuke.shimaoka@monash.edu
#SBATCH --job-name=makeStimDataBase_insilico
#SBATCH --time=5:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=130000
#SBATCH --array=1-5
module load matlab/r2021a
matlab -nodisplay -nodesktop -nosplash < makeStimDataBase_inSilico.m
