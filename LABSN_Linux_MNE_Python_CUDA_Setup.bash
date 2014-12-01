#! /bin/bash

## If you want mne-python to use CUDA (and you should, if your computer
## has a good NVIDIA graphics card), you should be sure to install the
## repo package providing the most recent NVIDIA drivers that your
## graphics card will support.  
## NOTE: using "nvidia-current" or "nvidia-current-updates" does NOT
## reliably give you the most recent drivers; for example, at time of
## writing "current" installs version 304, but the most current is 331.
## Find out which package is best for your machine, and edit this line: 
nvidia="nvidia-331-updates"

## Do you have MNE-python installed in both Python 2.x and Python 3.x?
p2k=true
p3k=true

## install Nvidia drivers
sudo apt-get install $nvidia
sudo nvidia-xconfig

## configure mne-python to use CUDA; also set the proper stim channel
## number for our neuromag system
mne_config="import mne; mne.set_config('MNE_USE_CUDA', 'true'); \
mne.set_config('MNE_STIM_CHANNEL', 'STI101')"
if [ $p2k = true ]; then
	python2 -c "$mne_config"
fi
if [ $p3k = true ]; then
	python3 -c  "$mne_config"
fi

## test by opening an interactive python session and importing mne; you
## should get a startup message saying "Enabling CUDA with 1.89 GB
## available memory" or something similar.
