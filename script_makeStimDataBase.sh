#!/bin/bash
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=daisuke.shimaoka@monash.edu
#SBATCH --job-name=Wrapper
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=130000
#SBATCH --array=1-2
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu
module load matlab
matlab -nodisplay -nodesktop -nosplash < makeStimDataBase.m
