#! /bin/bash

## If you want mne-python to use CUDA (and you should, if your computer
## has a good NVIDIA graphics card), you should be sure to install the
## repo package providing the most recent NVIDIA drivers that your
## graphics card will support.  
## NOTE: using "nvidia-current" or "nvidia-current-updates" does NOT
## reliably give you the most recent drivers; for example, at time of
## writing "current" installs version 304; the most current is 331.

## find out which package is best for your machine, and edit this line: 
nvidia="nvidia-331-updates"

## Do you have MNE-python installed in both Python 2.x and Python 3.x?
p2k=true
p3k=true

## install Nvidia drivers
sudo apt-get install $nvidia
sudo nvidia-xconfig

## configure mne-python to use CUDA; also set the proper stim channel
## number for our neuromag system 
if [ $p2k = true ]; then
	python2 -c "import mne; mne.set_config('MNE_USE_CUDA', 'true'); \
	mne.set_config('MNE_STIM_CHANNEL', 'STI101')"
fi
if [ $p3k = true ]; then
	python3 -c "import mne; mne.set_config('MNE_USE_CUDA', 'true'); \
	mne.set_config('MNE_STIM_CHANNEL', 'STI101')"
fi

## test by pening python and importing mne again; you should get a
## startup message saying "with CUDA" or something similar.
