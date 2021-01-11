#! /bin/bash
# Need to install gcc/g++/make in Ubuntu
GIT=${GIT:-git}
ROOT=build/

set -u
set -e

# Install python-devel package if not already available
# first, makes sure distutils.sysconfig usable
# We are not currently compiling the bindings by default, but it seems
# worth it to keep this section as we do have them and they will
# probably be used.
if ! $(python -c "import distutils.sysconfig" &> /dev/null); then
    echo "$0: WARNING: python library distutils.sysconfig not usable, this is necessary to figure out the path of Python.h." >&2
    echo "Proceeding with installation." >&2
else
  # get include path for this python version
  INCLUDE_PY=$(python -c "from distutils import sysconfig as s; print(s.get_python_inc())")
  if [ ! -f "${INCLUDE_PY}/Python.h" ]; then
      echo "$0 : ERROR: python-devel/python-dev not installed" >&2
      if which yum >&/dev/null; then
        # this is a red-hat system
        echo "$0: we recommend that you run (our best guess):"
        echo " sudo yum install python-devel"
      fi
      if which apt-get >&/dev/null; then
        # this is a debian system
        echo "$0: we recommend that you run (our best guess):"
        echo " sudo apt-get install python-dev"
      fi
      exit 1
  fi
fi

(
    if [ ! -d ${ROOT} ]; then mkdir -p ${ROOT}; fi
    cd ${ROOT}
    if [ ! -d ./phonetisaurus-g2p ] ; then
    $GIT clone https://github.com/AdolfVonKleist/Phonetisaurus.git phonetisaurus-g2p ||
    {
        echo  >&2 "$0: Warning: git clone operation ended unsuccessfully"
        echo  >&2 "  I will assume this is because you don't have https support"
        echo  >&2 "  compiled into your git "
        $GIT clone https://github.com/AdolfVonKleist/Phonetisaurus.git phonetisaurus-g2p

        if [ $? -ne 0 ]; then
        echo  >&2 "$0: Error git clone operation ended unsuccessfully"
        echo  >&2 "  Clone the github repository (https://github.com/AdolfVonKleist/Phonetisaurus.git)"
        echo  >&2 "  manually make and install in accordance with directions."
        fi
    }
    fi

    (
        cd phonetisaurus-g2p
        echo $PWD
        #checkout the current kaldi tag
        cur_branch=$(git branch | head -1 | awk '{print $2}')
        if [ $cur_branch != 'kaldi' ]; then
            $GIT checkout -b kaldi kaldi
        fi
        # --with-openfst-includes=${$KALDI_DIR}/include --with-openfst-libs=${$KALDI_DIR}/lib
        ./configure --prefix ${KALDI_DIR} --with-openfst-includes=${KALDI_DIR}/include --with-openfst-libs=${KALDI_DIR}/lib
        make -j5
        make install -j5
    )
)
