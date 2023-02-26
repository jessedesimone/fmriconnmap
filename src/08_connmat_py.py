#!/usr/bin/env python3

# import packages
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

class directories:
    '''Should be accessible in each module'''
    base_dir = '/Users/jessedesimone/DeSimone_Github' 
    pkg_dir = os.path.join(base_dir, 'fmriconnmap/')
    data_dir = os.path.join(pkg_dir, 'data')
    out_dir_base = os.path.join(pkg_dir, 'connmat')

# read file path for specified outdir
with open(directories.out_dir_base + "/_tmp_outpath.txt") as o:
    outpath = o.readline().strip('\n')

# file configuration
'''infiles'''
infile='grp_roi_means.txt'; fname=outpath+"/"+infile
roi_names='py_roi_labels.txt'; rname=outpath+"/"+roi_names

'''outfiles'''
outfile_csv='grp_corr.csv'; oname1=outpath+"/"+outfile_csv
outfile_mat='grp_corr.jpg'; oname2=outpath+"/"+outfile_mat

# define roi_names
# todo - create list based on input file - make automated
rf = pd.read_csv(rname, names=['roi_name']); roi_names=rf.roi_name.to_list()
#roi_names = ['DefaultMode.PCC', 'Salience.ACC', 'Motor.M1_L', 'Visual.Lateral_L', 'DorsalAttention.FEF_R', 'Limbic.Hipp_R']

# read in group roi means
df = pd.read_csv(fname, delimiter = ' ', names=roi_names)

# compute pearson correlation coefficients
cor = df.corr(method='pearson')
#print(cor)
cor.to_csv(oname1, index=False)

# create correlation matrix
sns.set_context('paper')
f, ax = plt.subplots(figsize=(8, 5))
plt.title('ROI Correlation Matrix', weight='bold', fontsize=12)
ax = sns.heatmap(cor, vmax=1, annot=False, cmap=sns.color_palette("viridis", as_cmap=True))
ax.set_xticklabels(
    ax.get_xticklabels(),
    rotation=45,
    horizontalalignment='right')
#plt.savefig(oname2)
plt.tight_layout()
plt.show()