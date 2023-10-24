#!/bin/bash
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=daisuke.shimaoka@monash.edu
#SBATCH --job-name=Wrapper
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=80000
#SBATCH --array=1-5
#SBATCH --gres=gpu:1
#SBATCH --partition=m3g
module load matlab
matlab -nodisplay -nodesktop -nosplash < wrapper_encoding.m
