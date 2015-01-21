#! /bin/bash -e
## Commands to be run when setting up a fresh system. If you intend to
## install Intel MKL, you should do so *BEFORE* running this script, and
## then set the "mkl" variable to "true" in order to allow compiling
## against the MKL libraries (you can still specify whether to compile
## against MKL on a case-by-case basis for each individual program).
mkl=false
## If mkl=true, you must also provide the install prefix you used when
## installing MKL:
mkl_prefix="/opt/intel"

## This script does *NOT* install MATLAB or Freesurfer. Information on
## MATLAB installation for LABS^N members is available on the lab wiki.
## Freesurfer's website has thorough instructions on installation.

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

## Do you want both Python 2.x and Python 3.x versions of the various
## python-related packages?
p2k=true
p3k=true

## Create a directory to house any custom builds. Rename if desired.
build_dir="$HOME/Builds"
mkdir -p $build_dir

## HDF5 (Heirarchical data format for large data sets)
## "serial", "openmpi", and "mpich" are all Ubuntu repository options,
## the latter two being parallel versions. If opting for parallel,
## "openmpi" is recommended. Compiling from source is also possible, but
## not really necessary; you can compile against Intel MKL ("intel"),
## OpenMPI ("source-mpi"), or the default system compilers ("system").
## Currently set to use version 1.8.13 (latest as of 2014-11-25). If not
## installing from repos, check website for newer version. Make sure to
## specify the URL for the .tar.gz, not .tar.bz2 version.
hdf="serial"
hdf_prefix="/opt" # a sub-folder "hdf5" is created here automatically
hdf_url="http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.13.tar.gz"

## OPEN MPI (Message passing interface for multi-threaded computing)
## Only necessary with HDF5 options "openmpi" or "source-mpi".
## Options are "intel" or "system" for the choice of compilers.
## Currently set to use version 1.8.3 (latest as of 2014-11-25). Check
## website for newer version before installing. Make sure to specify the
## URL for the .tar.gz and not .tar.bz2 version.
mpi="system"
mpi_prefix="/usr/local"
mpi_url="http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.3.tar.gz"

## NUMPY & SCIPY (de-facto standard for numeric computations and
## scientific functions in Python). Install options are "repo", "pip",
## "git", & "mkl". Both "git" and "mkl" mean compiling locally from
## source; the "git" option uses default system compilers, while "mkl"
## compiles against the MKL libraries.
numpy="repo"
scipy="repo"

## GITHUB SSH KEY AUTHORIZATION: Ensure that your computer's SSH key is
## tracked in github so you are allowed to access the lab git repositories.
## To do this, copy your computer's SSH public key into your github account
## under Github > Settings > SSH keys.  For more detailed instructions,
## go to <https://help.github.com/articles/generating-ssh-keys/> or
## google "github help generate ssh key."

## EXPYFUN and MNEFUN: Both come from GitHub. Options are "user" or
## "dev"; choose "dev" if you are likely to modify / contribute to the
## codebase, in addition to using it to run your experiments / analysis.
## If you choose "dev", then you should first fork the project from the
## LABSN GitHub account into your own account, and enter your GitHub
## username below. The script will set up your local clone to track your
## fork as "origin", and will create a second remote "upstream" that
## tracks the LABSN master.
github_username=""
expyfun="user"
mnefun="user"

## MNE PYTHON: core MNE analysis package. Options are "pip" or "git".
## If you want mne-python to use CUDA (and you should, if your computer
## has a good NVIDIA graphics card), there is a separate script to set
## that up, that you should run after this script succeeds.
mnepy="pip"

## PYEPARSE: analysis of eye-tracking and pupillometry data. Its
## dependencies are NumPy, h5py, and the EyeLink drivers / libraries.
## Pyeparse is a quasi-dependency of expyfun (since it is required by
## the pupillometry codeblocks), but is not otherwise required for
## expyfun installation or normal functioning. The only installation
## method supported is "git".
## Pandas is a soft requirement of pyeparse (it speeds up I/O),
## but is also general-purpose python data analysis library; options
## for pandas are "repo", "pip", "git".
pyeparse="none"
eyelink="none"
pandas="repo"

## All of the following have the same choices: "repo", "pip", or "git".
## Note that scikit-learn does not have a separate python3 version in
## the repos, so the p2k and p3k options do not differ for that package.
## Also note that some users like to install Spyder from the repos first
## to get the icon set, menu integration, etc, and then later install
## from pip or git to get the latest features. If this is you, then set
## Spyder to "repo" here, then run the pip or git installation lines
## after this script has been successfully run. For Pyglet, "git" is
## required for expyfun to work (and incidentally, for Pyglet "git"
## really means using pip to install the latest development tarball from
## the dev repo, which is actually a google code site, not GitHub).
mpl="repo"    # MATPLOTLIB: best-of-breed scientific plotting in python
skl="repo"    # SCIKIT-LEARN: machine learning algorithms in python
sea="repo"    # SEABORN: data visualization package built atop matplotlib
svgu="repo"   # SVG Utils: python tools for combining & manipulating SVGs
spyder="repo" # SPYDER: Python IDE tailored to scientific users
joblib="repo" # JOBLIB: python parallelization library
pyglet="git"  # PYGLET: python audio / visual interface layer

## The following aren't available in the Ubuntu repos, so the only
## choices are "pip" or "git".
skc="pip"   # SCIKITS.CUDA: SciPy toolkit interface to Nvidia's CUDA libraries
tdt="none"  # TDTPY:  Python wrappers for TDT's Active-X interface

## R and JULIA: Statistical programming environments. Options for R are
## "repo" and "cran", with "cran" being recommended (runs through
## apt-get, but adds a new source to /etc/apt/sources.list; similar to a
## PPA but more trustworthy as the source is an offical CRAN mirror).
## The recommended IDE for R is RStudio, which currently serves up
## binaries from its own website rather than through the repos, so you
## need to provide the URL for the most current version here.
rlang="none"
rstudio=false
rstudio_url="http://download1.rstudio.org/rstudio-0.98.1091-amd64.deb"
## Options for Julia are "ppa", "git", and "mkl". The PPA is run by a
## former LABS^N member, so is not really a risk/unknown like some PPAs
## are. There is currently no mature IDE for Julia. JuliaStudio for
## Linux is not compatible with the most recent version of Julia. There
## is a Julia plugin for the LightTable editor called Juno, that might
## be worth trying...
julia="none"
#juliastudio=false
#juliastudio_url="https://s3.amazonaws.com/cdn-common.forio.com/\
#julia-studio/0.4.4/julia-studio-linux-64-0.4.4.tar.gz"

## IMAGE PROCESSING APPS: inkscape, gimp, & image magick are useful for
## figure creation and image processing. Bleeding-edge versions are not
## offered here, since our image processing needs are fairly minimal.
## Hence, just need a boolean for whether to install them or not.
ink=true
gimp=true
magick=true

## ## ## ## ## ## ##
## GENERAL SETUP  ##
## ## ## ## ## ## ##
## These are general prerequisites that any system should probably have.
## Repo versions are typically best here, although installing through
## pip is possible for the python-related ones, as shown in the
## commented-out lines below.
sudo apt-get update
sudo apt-get install default-jre build-essential git-core cmake bzip2 \
liblzo2-2 liblzo2-dev zlib1g zlib1g-dev libfreetype6-dev libpng-dev \
libxml2-dev libxslt1-dev ssh-askpass
if [ $p2k = true ]; then
    sudo apt-get install cython python-nose python-coverage \
    python-setuptools python-pip
fi
if [ $p3k = true ]; then
    sudo apt-get install cython3 python3-nose python3-coverage \
    python3-setuptools python3-pip
fi
# pip install --user Cython nose coverage setuptools
# pip3 install --user Cython nose coverage setuptools

## ## ## ## ##
## OPEN MPI ##
## ## ## ## ##
if [ $hdf = "openmpi" ] || [ $hdf = "source-mpi" ]; then
    mpi_archive="${mpi_url##*/}"
    mpi_folder="${mpi_archive%.tar.gz}"
    cd
    wget "$mpi_url"
    tar -zxf "$mpi_archive"
    cd "$mpi_folder"
    if [ "$mpi" = "intel" ]; then
        flags="CC=icc CXX=icpc FC=ifort"
    fi
    ./configure --prefix="$mpi_prefix" $flags
    make -j 6 all
    sudo bash
    make install
    ## NOTE: the "sudo bash; make install" lines are equivalent to
    ## "sudo make install", except this way the ~/.bashrc file gets
    ## loaded first (which is not normally the case with sudo commands).
    ## That way, the intel compiler dirs are on the path during install.
    rm "~/$mpi_archive"
    rm -Rf "~/$mpi_folder"
fi

## ## ## ##
## HDF5  ##
## ## ## ##
if [ $hdf = "source-mpi" ] || [ $hdf = "intel" ] || [ $hdf = "system" ]
then
    hdf_archive=${hdf_url##*/}
    hdf_folder=${hdf_archive%.tar.gz}
    cd "$hdf_prefix"
    mkdir "hdf5"
    cd
    wget "$hdf_url"
    tar -zxf "$hdf_archive"
    cd "$hdf_folder"
    if [ $hdf = "source-mpi" ]; then
        export CC=mpicc
        flags="--disable-static"
    else  # $hdf = "intel" or "system"
        if [ $hdf = "intel" ]; then
            export CC=icc
            export F9X=ifort
            export CXX=icpc
        fi
        flags="--enable-fortran --enable-cxx --disable-static"
    fi
    ./configure --prefix="$hdf_prefix/hdf5" $flags
    make -j -l6
    make check
    make install
    make check-install
    cd
    rm "~/$hdf_archive"
    rm -Rf "~/$hdf_folder"
elif [ $hdf = "mpich" ]; then
    sudo apt-get install libhdf5-mpich2-7 libhdf5-mpich2-dev
elif [ $hdf = "openmpi" ]; then
    sudo apt-get install libhdf5-openmpi-7 libhdf5-openmpi-dev
elif [ $hdf = "serial" ]; then
    sudo apt-get install libhdf5-7 libhdf5-dev
fi

## ## ## ##
## NUMPY ##
## ## ## ##
if [ $numpy = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-numpy
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-numpy
    fi
elif [ $numpy = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user numpy
    fi
    if [ $p3k = true ]; then
        pip3 install --user numpy
    fi
elif [ $numpy = "git" ] || [ $numpy = "mkl" ]; then
    cd "$build_dir"
    git clone git://github.com/numpy/numpy.git
    cd numpy
    rm -Rf build  ## in case rebuilding
    if [ $mkl = true ] && [ $numpy = "mkl" ]; then
        ## generate site.cfg
        echo [mkl] > site.cfg
        echo library_dirs = "$mkl_prefix/mkl/lib/intel64" >> site.cfg
        echo include_dirs = "$mkl_prefix/mkl/include" >> site.cfg
        echo mkl_libs = mkl_rt >> site.cfg
        echo lapack_libs =   >> site.cfg
        flags="config --compiler=intelem build_clib --compiler=intelem \
        build_ext --compiler=intelem"
    else  # $numpy = "git"
        flags=""
    fi
    if [ $p2k = true ]; then
        python2 setup.py clean
        python2 setup.py $flags install --user
    fi
    if [ $p3k = true ]; then
        python3 setup.py clean
        python3 setup.py $flags install --user
    fi
fi

## ## ## ##
## SCIPY ##
## ## ## ##
if [ $scipy = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-scipy
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-scipy
    fi
elif [ $scipy = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user scipy
    fi
    if [ $p3k = true ]; then
        pip3 install --user scipy
    fi
elif [ $scipy = "git" ] || [ $scipy = "mkl" ]; then
    cd "$build_dir"
    git clone git://github.com/scipy/scipy.git
    cd scipy
    rm -Rf build  ## in case rebuilding
    if [ $mkl = true ] && [ $scipy = "mkl" ]; then
        flags="config --compiler=intelem --fcompiler=intelem \
        build_clib --compiler=intelem --fcompiler=intelem build_ext \
        --compiler=intelem --fcompiler=intelem"
    else  # $scipy = "git"
        flags=""
    fi
    if [ $p2k = true ]; then
        python2 setup.py clean
        python2 setup.py $flags install --user
    fi
    if [ $p3k = true ]; then
        python3 setup.py clean
        python3 setup.py $flags install --user
    fi
fi

## ## ## ## ## ##
## MATPLOTLIB  ##
## ## ## ## ## ##
if [ $mpl = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-matplotlib
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-matplotlib
    fi
elif [ $mpl = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user matplotlib
    fi
    if [ $p3k = true ]; then
        pip3 install --user matplotlib
    fi
elif [ $mpl = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/matplotlib/matplotlib.git
    cd matplotlib
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ##
##  PANDAS  ##
## ## ## ## ##
if [ $pandas = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-pandas python-pandas-lib
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-pandas python3-pandas-lib
    fi
elif [ $pandas = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user pandas
    fi
    if [ $p3k = true ]; then
        pip3 install --user pandas
    fi
elif [ $pandas = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/pydata/pandas.git
    cd pandas
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ##
## EYELINK  ##
## ## ## ## ##
## Install instructions adapted from the SR Research forums, accessible
## by logging in to this website as "labsner" with the labsner password:
## https://www.sr-support.com/showthread.php?16-EyeLink-Developers-Kit-for-Linux-%28Linux-Display-Software%29
## It can also be installed from this archive (but apt-get is easier):
## "http://download.sr-support.com/linuxDisplaySoftwareRelease/EyeLinkDisplaySoftware1.9_x64.tar.gz"
echo "deb http://download.sr-support.com/x64 /" | sudo tee -a /etc/apt/sources.list > /dev/null
sudo apt-get update
sudo apt-get -y install eyelink-display-software1.9

## ## ## ## ##
## PYEPARSE ##
## ## ## ## ##
if [ $pyeparse = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/pyeparse/pyeparse.git
    cd pyeparse
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ## ## ##
##  SCIKIT-LEARN  ##
## ## ## ## ## ## ##
if [ $skl = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-sklearn python-sklearn-lib
    fi
    if [ $p3k = true ]; then
        ## NOTE: no python3-* versions in repos (2014-11-25)
        sudo apt-get install python-sklearn python-sklearn-lib
    fi
elif [ $skl = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user scikit-learn
    fi
    if [ $p3k = true ]; then
        pip3 install --user scikit-learn
    fi
elif [ $skl = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/scikit-learn/scikit-learn.git
    cd scikit-learn
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ##
## SEABORN  ##
## ## ## ## ##
if [ $sea = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-patsy python-statsmodels \
        python-statsmodels-lib python-seaborn
    fi
    if [ $p3k = true ]; then
        ## NOTE: no p3k version of statsmodels in repo (2014-11-25)
        pip3 install --user statsmodels
        sudo apt-get install python3-patsy python3-seaborn
    fi
elif [ $sea = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user patsy statsmodels seaborn
    fi
    if [ $p3k = true ]; then
        pip3 install --user patsy statsmodels seaborn
    fi
elif [ $sea = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/pydata/patsy.git
    git clone git://github.com/statsmodels/statsmodels.git
    git clone git://github.com/mwaskom/seaborn.git
    for name in patsy statsmodels seaborn; do
        cd "$build_dir/$name"
        if [ $p2k = true ]; then
            rm -Rf build
            python2 setup.py install --user
        fi
        if [ $p3k = true ]; then
            rm -Rf build
            python3 setup.py install --user
        fi
    done
fi

## ## ## ## ## ## ##
##  SCIKITS.CUDA  ##
## ## ## ## ## ## ##
if [ $skc = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user scikits.cuda
    fi
    if [ $p3k = true ]; then
        pip3 install --user scikits.cuda
    fi
elif [ $skc = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/lebedov/scikits.cuda.git
    cd scikits.cuda
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ##
## TDTPY ##
## ## ## ##
if [ $tdt = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user TDTPy
    fi
    if [ $p3k = true ]; then
        pip3 install --user TDTPy
    fi
elif [ $tdt = "git" ]; then
    cd "$build_dir"
    hg clone https://bitbucket.org/bburan/tdtpy
    cd tdtpy
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ## ##
##  SVG UTILS  ##
## ## ## ## ## ##
if [ $svgu = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-cairosvg python-cssselect
        pip install --user tinycss cairocffi svgutils
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-cairosvg
        pip3 install --user tinycss cssselect cairocffi svgutils
    fi
elif [ $svgu = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user tinycss cssselect cairocffi cairosvg svgutils
    fi
    if [ $p3k = true ]; then
        pip3 install --user tinycss cssselect cairocffi cairosvg svgutils
    fi
elif [ $svgu = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/SimonSapin/tinycss.git
    git clone git://github.com/SimonSapin/cssselect.git
    git clone git://github.com/SimonSapin/cairocffi.git
    git clone git://github.com/Kozea/CairoSVG.git
    git clone git://github.com/btel/svg_utils.git
    for name in tinycss cssseleect cairocffi CairoSVG svg_utils; do
        cd "$build_dir/$name"
        if [ $p2k = true ]; then
            rm -Rf build
            python2 setup.py install --user
        fi
        if [ $p3k = true ]; then
            rm -Rf build
            python3 setup.py install --user
        fi
    done
fi

## ## ## ## ## ## ## ## ## ## ## ##
## INKSCAPE, GIMP, IMAGE MAGICK  ##
## ## ## ## ## ## ## ## ## ## ## ##
if [ $ink = true ]; then
    sudo apt-get install inkscape
fi
if [ $gimp = true ]; then
    sudo apt-get install gimp
fi
if [ $magick = true ]; then
    sudo apt-get install libmagickwand-dev
fi

## ## ## ## ##
##  SPYDER  ##
## ## ## ## ##
if [ $spyder = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-rope python-flake8 python-sphinx \
        pylint pyflakes python-sip python-qt4 spyder
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-rope python3-flake8 \
        python3-sphinx pylint pyflakes python3-sip python3-pyqt4 spyder3
    fi
elif [ $spyder = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user rope flake8 sphinx pylint
    fi
    if [ $p3k = true ]; then
        pip3 install --user rope_py3k flake8 sphinx pylint
    fi
elif [ $spyder = "git" ]; then
    cd "$build_dir"
    hg clone https://spyderlib.googlecode.com/hg/ spyderlib
    cd spyderlib
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
    ## to update spyder:
    # cd "$build_dir/spyder"
    # hg pull --update
    # python2 setup.py install --user
    # python3 setup.py install --user
fi

## ## ## ## ##
##  JOBLIB  ##
## ## ## ## ##
if [ $joblib = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-joblib
    fi
    if [ $p3k = true ]; then
        sudo apt-get install python3-joblib
    fi
elif [ $joblib = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user joblib
    fi
    if [ $p3k = true ]; then
        pip3 install --user joblib
    fi
elif [ $joblib = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/joblib/joblib.git
    cd joblib
    if [ $p2k = true ]; then
        rm -Rf build
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        rm -Rf build
        python3 setup.py install --user
    fi
fi

## ## ## ## ##
##  PYGLET  ##
## ## ## ## ##
if [ $pyglet = "repo" ]; then
    if [ $p2k = true ]; then
        sudo apt-get install python-pyglet
    fi
    if [ $p3k = true ]; then
        ## no separate pk3 version
        sudo apt-get install python-pyglet
    fi
elif [ $pyglet = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user pyglet
    fi
    if [ $p3k = true ]; then
        pip3 install --user pyglet
    fi
elif [ $pyglet = "git" ]; then
    pip install --user --upgrade http://pyglet.googlecode.com/archive/tip.zip
fi

## ## ## ## ##
## EXPYFUN  ##
## ## ## ## ##
cd "$build_dir"
if [ $expyfun = "user" ]; then
    git clone git@github.com:LABSN/expyfun.git
    cd expyfun
    directive="install"
elif [ $expyfun = "dev" ]; then
    git clone git@github.com:$github_username/expyfun.git
    cd expyfun
    git remote add upstream git@github.com:LABSN/expyfun.git
    directive="develop"
fi
if [ $p2k = true ]; then
    python2 setup.py $directive --user
fi
if [ $p3k = true ]; then
    python3 setup.py $directive --user
fi

## ## ## ## ##
##  MNEFUN  ##
## ## ## ## ##
cd "$build_dir"
if [ $mnefun = "user" ]; then
    git clone git@github.com:LABSN/mnefun.git
    cd mnefun
    directive="install"
elif [ $mnefun = "dev" ]; then
    git clone git@github.com:$github_username/mnefun.git
    cd mnefun
    git remote add upstream git@github.com:LABSN/mnefun.git
    directive="develop"
fi
if [ $p2k = true ]; then
    python2 setup.py $directive --user
fi
if [ $p3k = true ]; then
    python3 setup.py $directive --user
fi

## ## ## ## ## ##
## MNE-PYTHON  ##
## ## ## ## ## ##
if [ $mnepy = "pip" ]; then
    if [ $p2k = true ]; then
        pip install --user mne
    fi
    if [ $p3k = true ]; then
        pip3 install --user mne
    fi
elif [ $mnepy = "git" ]; then
    cd "$build_dir"
    git clone git://github.com/mne-tools/mne-python.git
    cd mne-python
    if [ $p2k = true ]; then
        python2 setup.py install --user
    fi
    if [ $p3k = true ]; then
        python3 setup.py install --user
    fi
fi

## ## ##
## R  ##
## ## ##
if [ $rlang = "cran" ] || [ $rlang = "repo" ] ; then
	if [ $rlang = "cran" ]; then
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
		codename=$(lsb_release -c -s)
		echo "deb http://cran.fhcrc.org/bin/linux/ubuntu $codename/" | \
		sudo tee /etc/apt/sources.list > /dev/null
		sudo apt-get update
	fi
	sudo apt-get install r-base r-base-dev libcurl4-openssl-dev
fi

## ## ## ##
## JULIA ##
## ## ## ##
if [ $julia = "ppa" ]; then
    #codename=$(lsb_release -c -s)
    #sudo echo "deb http://ppa.launchpad.net/staticfloat/juliareleases/\
    #ubuntu $codename main" >> /etc/apt/sources.list
    #sudo echo "deb-src http://ppa.launchpad.net/staticfloat/\
    #juliareleases/ubuntu $codename main" >> /etc/apt/sources.list
    sudo add-apt-repository ppa:staticfloat/juliareleases
    sudo apt-get update
    sudo apt-get install julia
elif [ $julia = "git" ] || [ $julia = "mkl" ]; then
    cd "$build_dir"
    git clone git://github.com/JuliaLang/julia.git
    cd julia
    if [ $mkl = true ] && [ $julia = "mkl" ]; then
        source "$mkl_prefix/mkl/bin/mklvars.sh" intel64 ilp64
        export MKL_INTERFACE_LAYER=ILP64
        echo USE_MKL = 1 >> Make.user
    fi
    make -j 6
    make testall
    echo export PATH="$(pwd):$PATH" >> ~/.bashrc
fi

## ## ## ## ##
## R STUDIO ##
## ## ## ## ##
if [ $rstudio = true ]; then
    rstudio_deb="${rstudio_url##*/}"
    cd
    wget "$rstudio_url"
    sudo dpkg -i "$rstudio_deb"
    rm "$rstudio_deb"
fi

## ## ## ## ## ## ##
##  JULIA STUDIO  ##
## ## ## ## ## ## ##
#if [ $juliastudio = true ]; then
#	juliastudio_archive="${juliastudio_url##*/}"
#	juliastudio_folder="${juliastudio_archive%.tar.gz}"
#	cd
#	wget "$juliastudio_url"
#	tar -zxf "$juliastudio_archive"
#	cd "$juliastudio_folder"
#	## TODO: do the installation
#	rm "~/$juliastudio_archive"
#	rm -Rf "~/$juliastudio_folder"
#fi
