#! /bin/bash
## Commands to be run when setting up a fresh system. Installs Intel MKL
## and builds NumPy, SciPy, numexpr, and Julia with MKL backend.
## Installs mne-python with CUDA support. Installs HDF5, PyTables,
## scikit-learn, scikits.cuda, pandas, tdtpy, pyglet, expyfun, R,
## and spyder. Includes notes on setup of freesurfer, MATLAB, and SSH.
## NOTE: commands indented and marked with ## TODO ## should not be run
## directly; they need editing or require some interaction on your part.

## ## ## ## ## ##
##  DECISIONS  ##
## ## ## ## ## ##
## Here you decide whether you want to use Ubuntu repositories (most
## conservative and stable), pip / PPA (middle ground), or git (bleeding
## edge) when installing the various packages and prerequisites, and
## specify any other installation options. The comments tell you which
## choices are available and what they mean. In all cases you can also
## specify "none" (or the empty string) if you don't want it installed
## at all, but be aware that many of the early-listed items are
## prerequisites for items further down the list.

## Do you have Intel MKL installed already?
mkl=false

## Do you want both Python 2.x and Python 3.x versions of everything?
p2k=true
p3k=true

## Create a directory to house any custom builds. Rename if desired.
build_dir="~/Builds"
mkdir $build_dir

## HDF5 OPTIONS
## "serial", "openmpi", and "mpich" are all Ubuntu repository options,
## the latter two being parallel versions. If opting for parallel, 
## "openmpi" is recommended. Compiling from source is also possible, but
## not really necessary; you can compile against Intel MKL ("intel"), 
## OpenMPI ("source-mpi"), or the default system compilers ("system").
hdf="serial"

## OPEN MPI: Only necessary with HDF5 options "openmpi" or "source-mpi".
## Options are "intel" or "system" for the choice of compilers.
mpi="system"
mpi_prefix="/usr/local"

## NUMPY & SCIPY OPTIONS: "repo", "pip", "git", & "mkl". mkl implies git
numpy="repo"
scipy="repo"

## All of the following have the same choices: "repo", "pip", or "git".
mpl="repo"    # MATPLOTLIB: best-of-breed scientific plotting in python
pd="repo"     # PANDAS: Python data analysis library
skl="repo"    # SCIKIT-LEARN: machine learning algorithms in python
sea="repo"    # SEABORN: data visualization package built atop matplotlib
svgu="repo"   # SVG Utils: python tools for combining & manipulating SVGs
spyder="repo" # SYPDER: Python IDE tailored to scientific users

## The following aren't available in the Ubuntu repos, so the only
## choices are "pip" or "git".
skc="pip"  # SCIKITS.CUDA: SciPy toolkit interface to NVIDIA's CUDA libraries
tdt="pip"  # TDTPY:  Python wrappers for TDT's Active-X interface

## IMAGE PROCESSING APPS: inkscape, gimp, & image magick are repo-only,
## so just need a boolean for whether to install them or not:
ink=true
gimp=true
magick=true

## DEPRECATED OPTIONS
# numexpr=true
# pytables=true

## EXPYFUN and MNEFUN: Both come from GitHub. Options are "normal" or
## "dev"; choose "dev" if you are likely to modify / contribute to the
## codebase, in addition to using it to run your experiments / analysis.
expyfun="install"
mnefun="install"

## R and JULIA: Statistical programming environments. Options for R are
## "repo" and "cran", with "cran" being recommended (runs through
## apt-get, but adds a new source to /etc/apt/sources.list). Options for
## Julia are "repo", "ppa", "git", and "mkl". mkl implies git. The PPA
## is run by a former LABS^N member, and so is less of a risk/unknown
## than most PPAs are.
rlang="cran" 
julia="ppa"

## ## ## ## ## ## ##
## GENERAL SETUP  ##
## ## ## ## ## ## ##
## These are general prerequisites that any system should probably have.
## Repo versions are typically best here, although installing through
## pip is possible for the python-related ones, as shown in the
## commented-out lines below.
sudo apt-get update
sudo apt-get install default-jre build-essential git-core cmake bzip2 liblzo2-2 liblzo2-dev zlib1g zlib1g-dev libfreetype6-dev libpng-dev libxml2-dev libxslt1-dev
if [ "$p2k" = true ]; then
	sudo apt-get install cython python-nose python-coverage python-setuptools python-pip
fi
if [ "$p3k" = true ]; then
	sudo apt-get install cython3 python3-nose python3-coverage python3-setuptools python3-pip
fi
# pip install --user Cython nose coverage setuptools
# pip3 install --user Cython nose coverage setuptools

## ## ## ## ##
## OPEN MPI ##
## ## ## ## ##
if [ "$hdf" = "openmpi" ] || [ "$hdf" = "source-mpi" ]
	## TODO: Version 1.8.3 (current as of 2014-11-25) 
	cd
	wget http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.3.tar.gz
	tar -zxf openmpi-1.8.3.tar.gz
	cd openmpi-1.8.3
	if [ "$mpi" = "intel" ]
		./configure --prefix=$mpi_prefix CC=icc CXX=icpc FC=ifort
	else
		./configure --prefix=$mpi_prefix
	fi
	make -j 6 all
	sudo bash
	make install
	## NOTE: the "sudo bash; make install" lines are equivalent to
	## "sudo make install", except this way the ~/.bashrc file gets
	## loaded first (which is not normally the case with sudo commands).
	## That way, the intel compiler dirs are on the path during install.
	rm ~/openmpi-1.8.3.tar.gz
	rm -r ~/openmpi-1.8.3
fi

# TODO: resume here.

## ## ## ##
## HDF5  ##
## ## ## ##
## NOTE: In general you should not try to compile HDF5 from source.
## Both serial and parallel versions of HDF5 binaries are available
## through standard Ubuntu repositories. Here is the serial version:
if [ "$hdf_pref" = "serial" ]; then
	sudo apt-get install libhdf5-7 libhdf5-dev
elif  [ "$hdf_pref" = "openmpi" ]; then
	sudo apt-get install libhdf5-openmpi-7 libhdf5-openmpi-dev
elif  [ "$hdf_pref" = "mpich" ]; then
	sudo apt-get install libhdf5-mpich2-7 libhdf5-mpich2-dev
else  # hdf_pref = "source"
	## NOTE: next lines may need sudo if you haven't chowned /opt.
	## NOTE: wget line may not be the most current version.
	cd /opt
	mkdir hdf5
	wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.13.tar.gz
	tar -zxf hdf5-1.8.13.tar.gz
	cd hdf5-1.8.13
	if [ "$hdf_compiler" = "mpi" ]; then
		## compile parallel HDF5 using MPI
		export CC=mpicc
		./configure --prefix=/opt/hdf5 --disable-static
	elif [ "$hdf_compiler" = "mkl" ]; then
		## compile serial HDF5 with intel compilers
		export CC=icc
		export F9X=ifort
		export CXX=icpc
		./configure --prefix=/opt/hdf5 --enable-fortran --enable-cxx --disable-static
	else  # hdf_compiler = "system"
		## compile serial HDF5 with default system compilers
		./configure --prefix=/opt/hdf5 --enable-fortran --enable-cxx --disable-static
	fi
	make -j -l6
	make check
	make install
	make check-install
	cd /opt
	rm -Rf ./hdf5-1.8.13
fi

## ## ## ##
## NUMPY ##
## ## ## ##
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		sudo apt-get install python-numpy
	fi
	if [ "$p3k" = true ]; then
		sudo apt-get install python3-numpy
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user numpy
	fi
	if [ "$p3k" = true ]; then
		pip3 install --user numpy
	fi
else  #  preferred_source = "git"
	cd $build_dir
	git clone git://github.com/numpy/numpy.git
	cd numpy
	## if rebuilding:
	# rm -Rf build
	if [ "$mkl" = true ]; then
		## generate site.cfg
		echo [mkl] >> site.cfg
		echo library_dirs = /opt/intel/mkl/lib/intel64 >> site.cfg
		echo include_dirs = /opt/intel/mkl/include >> site.cfg
		echo mkl_libs = mkl_rt >> site.cfg
		echo lapack_libs =   >> site.cfg
		if [ "$p2k" = true ]; then
			python2 setup.py clean
			python2 setup.py config --compiler=intelem build_clib --compiler=intelem build_ext --compiler=intelem install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py clean
			python3 setup.py config --compiler=intelem build_clib --compiler=intelem build_ext --compiler=intelem install --user
		fi
	else  # mkl = false
		if [ "$p2k" = true ]; then
			python2 setup.py clean
			python2 setup.py install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py clean
			python3 setup.py install --user
		fi
	fi
fi

## ## ## ## ##
## NUMEXPR  ##
## ## ## ## ##
## NumExpr is no longer needed since PyTables is no longer used by
## expyfun. 
# cd $build_dir
# git clone git@github.com:pydata/numexpr.git
# cd numexpr
## generate site.cfg (uses the same format as NumPy)
# echo [mkl] >> site.cfg
# echo library_dirs = /opt/intel/mkl/lib/intel64 >> site.cfg
# echo include_dirs = /opt/intel/mkl/include >> site.cfg
# echo mkl_libs = mkl_rt >> site.cfg
# echo lapack_libs =   >> site.cfg
## if rebuilding: 
# rm -Rf build  
# python2 setup.py build 
# python2 setup.py install --user
# cd; python2 -c "import numexpr; numexpr.test()"
## NOTE: the test() line above fails if run within $build_dir/numexpr,
## hence the cd to $HOME first
# cd $build_dir/numexpr
# rm -Rf build  
# python3 setup.py build 
# python3 setup.py install --user
# cd; python3 -c "import numexpr; numexpr.test()"

## ## ## ## ##
## PYTABLES ##
## ## ## ## ##
## PyTables is no longer a dependency of expyfun. It has been replaced
## by h5py.
# cd $build_dir
# git clone git@github.com:PyTables/PyTables.git
# cd PyTables
## if rebuilding: 
# make clean  
# python2 setup.py build_ext --inplace
# python2 setup.py install --user
# cd; python2 -c "import tables; tables.test()"
# cd $build_dir/PyTables
# make clean
# python3 setup.py build_ext --inplace
# python3 setup.py install --user
# cd; python3 -c "import tables; tables.test()"

## ## ## ##
## SCIPY ##
## ## ## ##
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		sudo apt-get install python-scipy
	fi
	if [ "$p3k" = true ]; then
		sudo apt-get install python3-scipy
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user scipy
	fi
	if [ "$p3k" = true ]; then
		pip3 install --user scipy
	fi
else  #  preferred_source = "git"
	cd $build_dir
	git clone git://github.com/scipy/scipy.git
	cd scipy
	if [ "$mkl" = true ]; then
		if [ "$p2k" = true ]; then
			python2 setup.py clean
			python2 setup.py config --compiler=intelem --fcompiler=intelem build_clib --compiler=intelem --fcompiler=intelem build_ext --compiler=intelem --fcompiler=intelem install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py clean
			python3 setup.py config --compiler=intelem --fcompiler=intelem build_clib --compiler=intelem --fcompiler=intelem build_ext --compiler=intelem --fcompiler=intelem install --user
		fi
	else  # mkl = false
		if [ "$p2k" = true ]; then
			python2 setup.py clean
			python2 setup.py install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py clean
			python3 setup.py install --user
		fi
	fi
fi

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## MATPLOTLIB, SCIKIT-LEARN, PANDAS, SCIKITS.CUDA, TDTPY ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## MATPLOTLIB: best-of-breed for scientific plotting in python
## SCIKIT-LEARN: machine learning algorithms in python
## PANDAS: Python data analysis library (similar to numpy record arrays)
## SCIKITS.CUDA: SciPy toolkit interface to NVIDIA's CUDA libraries
## TDTPY:  Python wrappers for TDT's Active-X interface
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		# NOTE: no repo version of scikits.cuda or TDTPy available
		sudo apt-get install python-matplotlib python-sklearn python-sklearn-lib python-pandas python-pandas-lib 
		pip install --user scikits.cuda TDTPy
	fi
	if [ "$p3k" = true ]; then
		# NOTE: no p3k version of sklearn is available in the repos
		# NOTE: no repo version of scikits.cuda or tdtPy available
		sudo apt-get install python3-matplotlib python3-pandas python3-pandas-lib
		pip3 install --user scikit-learn scikits.cuda TDTPy
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user matplotlib pandas scikit-learn scikits.cuda TDTPy
	fi
	if [ "$p3k" = true ]; then
		pip3 install --user matplotlib pandas scikit-learn scikits.cuda TDTPy
	fi
else  #  preferred_source = "git"
	cd $build_dir
	git clone git://github.com/matplotlib/matplotlib.git
	git clone git://github.com/scikit-learn/scikit-learn.git
	git clone git://github.com/pydata/pandas.git
	git clone git://github.com/lebedov/scikits.cuda.git
	hg clone https://bitbucket.org/bburan/tdtpy
	for name in matplotlib scikit-learn pandas scikits.cuda tdtpy; do
		cd $build_dir/$name
		if [ "$p2k" = true ]; then
			python setup.py install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py install --user
		fi
	done
fi

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## SEABORN (data visualization package built atop matplotlib)  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		sudo apt-get install python-patsy python-statsmodels python-statsmodels-lib python-seaborn
	fi
	if [ "$p3k" = true ]; then
		# NOTE: no p3k version of statsmodels in repo
		sudo apt-get install python3-patsy python3-seaborn
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user patsy statsmodels seaborn
	fi
	if [ "$p3k" = true ]; then
		# NOTE: no p3k version of statsmodels in repo; pip3 may not work
		pip3 install --user patsy statsmodels seaborn
	fi
else  #  preferred_source = "git"
	cd $build_dir
	git clone git@github.com:pydata/patsy.git
	git clone git@github.com:statsmodels/statsmodels.git
	git clone git@github.com:mwaskom/seaborn.git
	for name in patsy statsmodels seaborn; do
		cd $build_dir/$name
		if [ "$p2k" = true ]; then
			python setup.py install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py install --user
		fi
	done
fi

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  IMAGE PROCESSING / FIGURE CREATION HELPERS  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
sudo apt-get install inkscape gimp libmagickwand-dev
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		sudo apt-get install python-cairosvg python-cssselect
		pip install --user tinycss cairocffi svgutils
	fi
	if [ "$p3k" = true ]; then
		sudo apt-get install python3-cairosvg
		pip3 install --user tinycss cssselect cairocffi svgutils
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user tinycss cssselect cairocffi cairosvg svgutils
	fi
	if [ "$p3k" = true ]; then
		pip3 install --user tinycss cssselect cairocffi cairosvg svgutils
	fi
else  #  preferred_source = "git"
	cd $build_dir
	git clone git@github.com:SimonSapin/tinycss.git
	git clone git@github.com:SimonSapin/cssselect.git
	git clone git@github.com:SimonSapin/cairocffi.git
	git clone git@github.com:Kozea/CairoSVG.git
	git clone git@github.com:btel/svg_utils.git
	for name in tinycss cssseleect cairocffi CairoSVG svg_utils; do
		cd $build_dir/$name
		if [ "$p2k" = true ]; then
			python setup.py install --user
		fi
		if [ "$p3k" = true ]; then
			python3 setup.py install --user
		fi
	done
fi

## ## ## ## ##
##  SPYDER  ##
## ## ## ## ##
## (get repo version first to get icon set, menu integration, etc, then
## install tip)
if [ "$preferred_source" = "apt-get" ]; then
	if [ "$p2k" = true ]; then
		sudo apt-get install python-rope python-flake8 python-sphinx pylint pyflakes python-sip python-qt4 spyder
	fi
	if [ "$p3k" = true ]; then
		sudo apt-get install python3-rope python3-flake8 python3-sphinx pylint pyflakes python3-sip python3-pyqt4 spyder3
	fi
elif [ "$preferred_source" = "pip" ]; then
	if [ "$p2k" = true ]; then
		pip install --user rope flake8 sphinx pylint
	fi
	if [ "$p3k" = true ]; then
		pip3 install --user rope_py3k flake8 sphinx pylint
	fi
else  #  preferred_source = "git"
	cd $build_dir
	hg clone https://spyderlib.googlecode.com/hg/ spyderlib
	cd spyderlib
	if [ "$p2k" = true ]; then
		python2 setup.py install --user
	fi
	if [ "$p3k" = true ]; then
		python3 setup.py install --user
	fi
fi
## to update spyder:
# cd $build_dir/spyder
# hg pull --update
# python setup.py install --user

## ## ## ## ##
## EXPYFUN  ##
## ## ## ## ##
## Prerequisites:
pip install --user --upgrade http://pyglet.googlecode.com/archive/tip.zip
pip install --user joblib

## most people will want a typical installation like this:
cd $build_dir
git clone git@github.com/LABSN/expyfun.git
cd expyfun
python setup.py install --user
## if you're likely to help develop expyfun, do this instead:
## go to GitHub and fork LABSN/expyfun to your own git account. Then:
# cd $build_dir
# git clone git@github.com/<INSERT_YOUR_GIT_USERNAME_HERE>/expyfun.git
# cd expyfun
# python setup.py develop --user
## add LABSN repo as "upstream" (another remote repo alongside "origin")
# git remote add upstream git@github.com/LABSN/expyfun.git

## ## ## ## ## ##
## MNE-PYTHON  ##
## ## ## ## ## ##
cd $build_dir
git clone git://github.com/mne-tools/mne-python.git
cd mne-python
## can use "develop" instead of "install" (no compiled code in package):
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
cd $build_dir
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
