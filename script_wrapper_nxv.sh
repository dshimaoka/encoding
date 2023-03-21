#!/bin/bash
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=daisuke.shimaoka@monash.edu
#SBATCH --job-name=Wrapper_nxv_60arrays
#SBATCH --time=09:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=33000
#SBATCH --array=1-60
#SBATCH --gres=gpu:1
#SBATCH --partition=m3g
module load matlab
matlab -nodisplay -nodesktop -nosplash < wrapper_encoding_nxv.m
