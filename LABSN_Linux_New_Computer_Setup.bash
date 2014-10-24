#! /bin/bash
## Commands to be run when setting up a fresh system. Installs Intel MKL
## and builds NumPy, SciPy, numexpr, and Julia with MKL backend. 
## Installs mne-python with CUDA support. Installs HDF5, PyTables, 
## scikit-learn, scikits.cuda, pandas, tdtpy, pyglet, expyfun, R, 
## and spyder. Includes notes on setup of freesurfer, MATLAB, and SSH.
## NOTE: commands indented and marked with ## TODO ## should not be run
## directly; they need editing or require some interaction on your part.

## ## ## ## ## ## ## 
## GENERAL SETUP  ##
## ## ## ## ## ## ## 
## Prerequisites for MKL, NumPy, SciPy, mne-python, PyTables, svgutils
sudo apt-get update
sudo apt-get install default-jre build-essential git-core cython \
cython3 python-nose python3-nose python-coverage python3-coverage \
python-setuptools python3-setuptools python-pycuda python3-pycuda \
python-pip python3-pip cmake bzip2 liblzo2-2 liblzo2-dev zlib1g \
zlib1g-dev libfreetype6-dev libpng-dev libxml2-dev libxslt1-dev

## Create a directory to house your custom builds. Rename if desired.
builddir=~/Builds
mkdir $builddir

## ## ## ## ## ## 
##  INTEL MKL  ##
## ## ## ## ## ##
	## TODO ##
	## download Intel parallel studio and unzip.
	## you really only need the MKL, C++, and Fortran compilers, but
	## install the whole studio if you like. If you have problems, 
	## Google "NumPy/SciPy with Intel MKL" to find Intel's guide. Pay 
	## special attention to setting the environment variables correctly.
	cd /PATH/TO/UNPACKED/MKL/INSTALLER
sh install_GUI.sh
## do some GUI stuff...
## Now make sure the system can find MKL. Assuming you installed to 
## /opt/intel (the default):
sudo echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/intel-mkl.conf
sudo echo "/opt/intel/lib/intel64" >> /etc/ld.so.conf.d/intel-mkl.conf
echo "source /opt/intel/bin/compilervars.sh intel64" >> ~/.bashrc
sudo ldconfig
## refresh the .bashrc file to get the MKL environment variables set
source ~/.bashrc  

## ## ## ## ## 
## OPEN MPI ##
## ## ## ## ## 
	## TODO ##
	## NOTE: This is only necessary if you want to run h5py with 
	## parallelization.
	## Download source from http://www.open-mpi.org/ and unzip. 
	## Google "build mpi with intel compiler" for instructions.
	# cd /PATH/TO/UNPACKED/OPENMPI/INSTALLER
	# ./configure --prefix=/usr/local CC=icc CXX=icpc FC=ifort
	# make -j 6 all
	# sudo bash 
	# make install
	## NOTE: the "sudo bash; make install" lines are equivalent to
	## "sudo make install", except this way the ~/.bashrc file gets
	## loaded first (which is not normally the case with sudo commands).
	## That way, the intel compiler dirs are on the path during install.

## ## ## ##
## HDF5  ##
## ## ## ##
## NOTE: In general you should not try to compile HDF5 from source.
## Both serial and parallel versions of HDF5 binaries are available
## through standard Ubuntu repositories. Here is the serial version:
sudo apt-get install libhdf5-7 libhdf5-dev
## Parallel OPENMPI version (recommended for use with h5py):
# sudo apt-get install libhdf5-openmpi-7 libhdf5-openmpi-dev 
## Parallel MPICH version:
# sudo apt-get install libhdf5-mpich2-7 libhdf5-mpich2-dev
## If you really do need to build HDF5 from source:
# cd /opt
# mkdir hdf5
## NOTE: following three lines may not be the most current version:
# wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.13.tar.gz
# tar -zxf hdf5-1.8.13.tar.gz
# cd hdf5-1.8.13
## OPTION 1: compile serial HDF5 with intel compilers
# export CC=icc
# export F9X=ifort
# export CXX=icpc
# ./configure --prefix=/opt/hdf5 --enable-fortran --enable-cxx --disable-static
## OPTION 2: compile parallel HDF5 using MPI
# export CC=mpicc
# ./configure --prefix=/opt/hdf5 --disable-static
## EITHER OPTION:
# make -j -l6
# make check
# make install
# make check-install
# cd /opt
# rm -Rf ./hdf5-1.8.13

## ## ## ## ## ## ## ## ## ## ## ## ##
## h5py (python interface to HDF5)  ##
## ## ## ## ## ## ## ## ## ## ## ## ##
## Standard installation:
pip install --user h5py
pip3 install --user h5py
## Can also run parallelized, when using an mpi version of HDF5, with
## the help of mpi4py:
# pip install --user mpi4py
## OR:
# cd $builddir
# git clone git@bitbucket.org/mpi4py/mpi4py.git
# cd mpi4py
# python setup.py build
# python setup.py install --user

## Now install h5py:
# git clone git@github.com:h5py/h5py.git
# cd h5py
# export CC=mpicc
# export HDF5_DIR=/path/to/hdf5
# python setup.py build --mpi
# python setup.py test
# python setup.py install --user
# cd
## then in python, run:
# import h5py
# h5py.run_tests()

## ## ## ## 
## NUMPY ##
## ## ## ##
cd $builddir
git clone git://github.com/numpy/numpy.git
cd numpy
## generate site.cfg
echo [mkl] >> site.cfg
echo library_dirs = /opt/intel/mkl/lib/intel64 >> site.cfg
echo include_dirs = /opt/intel/mkl/include >> site.cfg
echo mkl_libs = mkl_rt >> site.cfg
echo lapack_libs =   >> site.cfg
## if rebuilding: 
# rm -Rf build  
python2 setup.py clean
python2 setup.py config --compiler=intelem build_clib --compiler=intelem build_ext --compiler=intelem install --user
python3 setup.py clean
python3 setup.py config --compiler=intelem build_clib --compiler=intelem build_ext --compiler=intelem install --user

## ## ## ## ## 
## NUMEXPR  ##
## ## ## ## ##
cd $builddir
git clone git@github.com:pydata/numexpr.git
cd numexpr
## generate site.cfg (uses the same format as NumPy)
echo [mkl] >> site.cfg
echo library_dirs = /opt/intel/mkl/lib/intel64 >> site.cfg
echo include_dirs = /opt/intel/mkl/include >> site.cfg
echo mkl_libs = mkl_rt >> site.cfg
echo lapack_libs =   >> site.cfg
## if rebuilding: 
# rm -Rf build  
python2 setup.py build 
python2 setup.py install --user
cd; python2 -c "import numexpr; numexpr.test()"
## NOTE: the test() line above fails if run within $builddir/numexpr,
## hence the cd to $HOME first
cd $builddir/numexpr
rm -Rf build  
python3 setup.py build 
python3 setup.py install --user
cd; python3 -c "import numexpr; numexpr.test()"

## ## ## ## ## 
## PYTABLES ##
## ## ## ## ##
cd $builddir
git clone git@github.com:PyTables/PyTables.git
cd PyTables
## if rebuilding: 
# make clean  
python2 setup.py build_ext --inplace
python2 setup.py install --user
cd; python2 -c "import tables; tables.test()"
cd $builddir/PyTables
make clean
python3 setup.py build_ext --inplace
python3 setup.py install --user
cd; python3 -c "import tables; tables.test()"

## ## ## ## 
## SCIPY ##
## ## ## ##
cd $builddir
git clone git://github.com/scipy/scipy.git
cd scipy
python2 setup.py clean
python2 setup.py config --compiler=intelem --fcompiler=intelem build_clib --compiler=intelem --fcompiler=intelem build_ext --compiler=intelem --fcompiler=intelem install --user
python3 setup.py clean
python3 setup.py config --compiler=intelem --fcompiler=intelem build_clib --compiler=intelem --fcompiler=intelem build_ext --compiler=intelem --fcompiler=intelem install --user
## Those SciPy compilations will take a while, go get a cup of coffee.

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## MATPLOTLIB, SCIKIT-LEARN, PANDAS, SCIKITS.CUDA, TDTPY ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
cd $builddir
## MATPLOTLIB: best-of-breed for scientific plotting in python
## SCIKIT-LEARN: machine learning algorithms in python
## PANDAS: Python data analysis library (similar to numpy record arrays)
## SCIKITS.CUDA: SciPy toolkit interface to NVIDIA's CUDA libraries
## TDTPY:  Python wrappers for TDT's Active-X interface
git clone git://github.com/matplotlib/matplotlib.git
git clone git://github.com/scikit-learn/scikit-learn.git
git clone git://github.com/pydata/pandas.git
git clone git://github.com/lebedov/scikits.cuda.git
hg clone https://bitbucket.org/bburan/tdtpy
for name in matplotlib scikit-learn pandas scikits.cuda tdtpy; do
	cd $builddir/$name
	## TODO: check whether all these can be done with both py2 & py3
	python setup.py install --user
done

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## SEABORN (data visualization package built atop matplotlib)  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
pip install --user patsy statsmodels seaborn
## or for the development version of seaborn:
# cd $builddir
# git clone git@github.com:mwaskom/seaborn.git
# cd seaborn
# pip install --user .
## this might also work instead of the "pip" line:
# python setup.py develop --user

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  IMAGE PROCESSING / FIGURE CREATION HELPERS  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
sudo apt-get install inkscape gimp libmagickwand-dev
pip install --user tinycss cssselect cairocffi cairosvg svgutils
## If you're likely to hack on it, svgutils can also be installed via: 
# cd $builddir
# git clone git@github.com:btel/svg_utils.git
# cd svg_utils
# python setup.py install --user

## ## ## ## ## 
##  SPYDER  ##
## ## ## ## ##
## (get repo version first to get icon set, menu integration, etc, then
## install tip)
pip install --user rope flake8 sphinx pylint
sudo apt-get install spyder
cd $builddir
hg clone https://spyderlib.googlecode.com/hg/ spyderlib
cd spyderlib
python2 setup.py install --user
## to update spyder:
# cd $builddir/spyder
# hg pull --update
# python setup.py install --user
## If you want to run python3 inside the Spyder console, it is 
## recommended to install a python3 version of Spyder (invoke as
## "spyder3"; it can coexist peacefully with a py2 Spyder install):
sudo apt-get install python3-sip python3-pyqt4
pip3 install --user rope_py3k flake8 sphinx pylint
cd $builddir/spyderlib
python3 setup.py install --user


## ## ## ## ##
## EXPYFUN  ##
## ## ## ## ##
## Prerequisites:
pip install --user --upgrade http://pyglet.googlecode.com/archive/tip.zip
pip install --user joblib

## most people will want a typical installation like this:
cd $builddir
git clone git@github.com/LABSN/expyfun.git
cd expyfun
python setup.py install --user
## if you're likely to help develop expyfun, do this instead:
## go to GitHub and fork LABSN/expyfun to your own git account. Then:
# cd $builddir
# git clone git@github.com/<INSERT_YOUR_GIT_USERNAME_HERE>/expyfun.git
# cd expyfun
# python setup.py develop --user
## add LABSN repo as "upstream" (another remote repo alongside "origin")
# git remote add upstream git@github.com/LABSN/expyfun.git

## ## ## ## ## ##
## MNE-PYTHON  ##
## ## ## ## ## ##
cd $builddir
git clone git://github.com/mne-tools/mne-python.git
cd mne-python
## could use "develop" instead of "install" (no compiled code in package):
python setup.py install --user
## set up mne-python to use CUDA. Note that "331" was the most current
## version at time of writing; check to see what is most appropriate for
## your system
sudo apt-get install nvidia-331-updates
sudo nvidia-xconfig
	## TODO ##
	## now reboot, then in python do:
	# import mne
	# mne.set_config('MNE_USE_CUDA', 'true')
	## set the proper stim channel number for our neuromag system
	# mne.set_config('MNE_STIM_CHANNEL', 'STI101')
	## test by closing python, reopening, and importing mne again

## ## ## ## ## ##
## FREESURFER  ##
## ## ## ## ## ##
	## TODO ##
	## there's a thorough install/setup tutorial on their website.
	## http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall
	## Probably the only prerequisite you won't already have is:
	sudo apt-get install tcsh

## ## ## ## ##
##  MATLAB  ##
## ## ## ## ##
	## TODO ##
	## Install MATLAB using download agent or ISO
	## TODO ##
	## Setup MATLAB license manager using the script on the lab wiki
	## TODO ##
	## Install psychtoolbox: see http://psychtoolbox.org/PsychtoolboxDownload

## ## ## ##
## JULIA ##
## ## ## ##
cd $builddir
git clone git@github.com:JuliaLang/julia.git
cd julia
source /opt/intel/mkl/bin/mklvars.sh intel64 ilp64
export MKL_INTERFACE_LAYER=ILP64
echo USE_MKL = 1 >> Make.user
## if you don't want multithreaded compilation just use "make":
make -j 6
make testall
echo export PATH="$(pwd):$PATH" >> ~/.bashrc

## ## ##
## R  ##
## ## ##
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
	## TODO ##
	## update "trusty" on following line to match your release version:
	sudo echo "deb http://cran.r-project.org/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list
sudo apt-get update
sudo apt-get install r-base r-base-dev
	## TODO ##
	## As of August 2014, Rstudio is not in the Ubuntu repos, 
    ## so download the .deb from Rstudio website & install.
	## Some (probably) useful packages to install from within R: 
	## install.packages(c('tidyr', 'devtools', 'ez', 'ggplot2', 
	## 'Hmisc', 'lme4', 'plyr', 'reshape', 'stringi', 'zoo'))

## ## ## ## ## ##
## NETWORKING  ##
## ## ## ## ## ##
sudo apt-get install openssh-server
	## TODO ##
	## First make sure you're getting a static IP (check network
	## settings for eth0). For added security, change port number to
	## something other than 22 in /etc/ssh/sshd_config, then access via:
	# ssh -p 1234 <username>@<hostname>.ilabs.uw.edu 
	## (where 1234 is the port you chose)

## RUNNING FIREFOX THROUGH AN SSH TUNNEL
## This sets up a pseudo-VPN for browser traffic only (useful if, e.g.,
## you're in a foreign country that blocks some websites). To avoid 
## changing these settings back and forth all the time, first set up a
## new Firefox profile by running "firefox -P" on the command line. 
## Create a new profile with a sensible name like "ssh" or "tunnel".
## Start Firefox with that profile, then go to:
## "Preferences > Advanced > Network > Settings" and choose "Manual 
## Proxy Configuration". Set your SOCKS host to 127.0.0.1, port 8080,
## use SOCKS v5, and check the "Remote DNS" box. Now you can run: 
# ssh -C2qTnN -D 8080 <name>@<hostname>
## ...before you launch Firefox, and all your browser traffic will be
## routed through your <hostname> computer and encrypted. Don't forget
## to add the flag "-p 1234" to the ssh command if you've configured 
## ssh to listen on a non-default port (as recommended above). Note that
## the Firefox profile editor allows you to select a default profile, so
## that can be an easy way to switch settings for the duration of your
## journey abroad, then switch back upon returning home. If you need to
## switch back and forth between tunnel and no tunnel on a regular
## basis, you can set your normal Firefox profile as the default, then
## use the following command to invoke the tunneled version (assuming
## the name of your proxied profile is "sshtunnel"): 
#ssh -C2qTnN -D 8080 <name>@<hostname> & tunnelpid=$! && sleep 3 && firefox -P sshtunnel && kill $tunnelpid
## this will capture the PID of the SSH tunnel instance, and kill it 
## when Firefox closes normally (you'll need to close it manually if
## Firefox crashes or is force-quit). 

## XRDP: remote desktop server
sudo apt-get install xrdp
## Setting up your machine as a VPN server is a pain.
## see instructions here if you must do it anyway:
## http://openvpn.net/index.php/open-source/documentation/howto.html
## these commands will get you started...
# sudo apt-get install openvpn bridge-utils easy-rsa
# sudo cp -r /usr/share/easy-rsa /etc/openvpn/
# sudo chown -R $USER /etc/openvpn/easy-rsa
	## TODO ##
	## now edit /etc/openvpn/easy-rsa/vars
	## in particular, set VPN port to 2345 (or whatever you want)
	# cd /etc/openvpn/easy-rsa
	# . ./vars
	# ./clean-all
	# ./build-ca
	# ./build-key-server
	# ./build-key-pass MyClientCPUName
	# ./build-dh
	## move client keys to client machine
	## set up VPN autostart

## ## ## ## ##
## FIREWALL ##
## ## ## ## ##
## NOTE: you don't strictly NEED to set up a firewall, as *NIX is pretty
## careful about what it allows in. This is especially true if you set
## SSH to reject password-based connections and only use preshared keys.
## Nonetheless, if you want to set up a strong firewall, this is a good
## starting point:
## (port numbers should match what you set for SSH and VPN above)
# sudo iptables -A INPUT -p tcp --dport 1234 -j ACCEPT  # incoming SSH
# sudo iptables -A INPUT -p tcp --sport 1234 -j ACCEPT  # outgoing SSH
# sudo iptables -A INPUT -p udp -m udp --dport 2345 -j ACCEPT  # incoming VPN
# sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # incoming web traffic
## probably will also need a line for the default HTTPS port (and
## possibly others). Google is your friend here. Finally, add a line to
## reject everything not explicitly allowed above. You will need to save
## changes (again, see Google for different ways to do this) otherwise
## the settings will only last for the current login session.

## ## ## ##
## RAID  ##
## ## ## ##
sudo apt-get install mdadm
	## TODO ##
    ## This is an example only. Customize to suit your system.
	## This will create a RAID level=1 (mirror) at /dev/md0 comprising
	## n=2 physical drives (sdc and sdd) 
	sudo mdadm --create /dev/md0 -l 1 -n 2 /dev/sdc1 /dev/sdd1  
	## If the RAID had already been built previously:
	# sudo mdadm --assemble /dev/md0 /dev/sdc1 /dev/sdd1  
## automount at startup (edit MOUNTPT as desired):
MOUNTPT="/media/raid"
sudo mkdir $MOUNTPT
UUID=sudo blkid /dev/md0 | cut -d '"' -f2
sudo echo "UUID=$UUID $MOUNTPT ext4 defaults 0 0" >> /etc/fstab 
