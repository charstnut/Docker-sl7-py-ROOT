# Using scientific linux as base
FROM sl:7

ENV ROOT_VERSION=6.18.00

COPY packages packages

RUN yum update -y
RUN yum install -y yum-conf-epel.noarch
RUN yum install -y $(cat packages) --skip-broken
RUN rm -f /packages

# Clean
RUN yum clean all && rm -rf /var/cache/yum

# Set up pip
RUN pip3 install --no-cache-dir --upgrade pip setuptools numpy

# Download ROOT
WORKDIR /root
RUN curl -O https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz \
    && tar xzf root_v${ROOT_VERSION}.source.tar.gz \
    && rm -rf ${HOME}/root_v${ROOT_VERSION}.source.tar.gz

# Install
WORKDIR /tmp
RUN cmake3 ${HOME}/root-${ROOT_VERSION}/ \
    -Dcxx11=ON \
    -Dfail-on-missing=ON \
    -Dgnuinstall=ON \
    -Drpath=ON \
    -Dbuiltin_afterimage=OFF \
    -Dbuiltin_ftgl=OFF \
    -Dbuiltin_gl2ps=OFF \
    -Dbuiltin_glew=OFF \
    -Dbuiltin_tbb=ON \
    -Dbuiltin_unuran=OFF \
    -Dbuiltin_vdt=ON \
    -Dbuiltin_veccore=ON \
    -Dbuiltin_xrootd=OFF \
    -Darrow=OFF \
    -Dcastor=OFF \
    -Dchirp=OFF \
    -Dgeocad=OFF \
    -Dglite=OFF \
    -Dhdfs=OFF \
    -Dmonalisa=OFF \
    -Doracle=OFF \
    -Dpythia6=OFF \
    -Drfio=OFF \
    -Droot7=OFF \
    -Dsapdb=OFF \
    -Dsrp=OFF \
    -Dvc=OFF \
    -Dpython3=ON \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -DPYTHON_INCLUDE_DIR:PATH=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -DPYTHON_INCLUDE_DIR2:PATH=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") \
    -DPYTHON_LIBRARY:FILEPATH=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
    && cmake3 --build . -- -j$(nproc) \
    && cmake3 --build . --target install \
    && rm -rf ${HOME}/root-${ROOT_VERSION} /tmp/*

ENV PYTHONPATH /usr/local/lib
RUN echo ". /usr/local/bin/thisroot.sh" >> ~/.bashrc

# TODO: Get latest tini version automatically (see anaconda docker)
# ENV TINI_VERSION v0.18.0
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
# RUN chmod +x /usr/bin/tini

CMD [ "/bin/bash" ]

# Another way of installing ROOT (in case building fails)
# https://redmine.jlab.org/projects/podd/wiki/ROOT_Installation_Guide

# Set python3 as default (note yum will not work afterwards)
# RUN ln -fs /usr/bin/python3 /usr/bin/python && \
#     ln -sf /usr/bin/python3-config /usr/bin/python-config && \
#     ln -sf /usr/bin/pip3 /usr/bin/pip