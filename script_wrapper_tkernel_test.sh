#!/bin/bash
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=daisuke.shimaoka@monash.edu
#SBATCH --job-name=Wrapper_tkernel
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-tasks=8
#SBATCH --mem-per-cpu=33000
#SBATCH --array=1-7
#SBATCH --gres=gpu:1
#SBATCH --partition=m3h
module load matlab
matlab -nodisplay -nodesktop -nosplash < wrapper_encoding_tkernel_test.m
