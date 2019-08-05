# Using scientific linux as base
FROM sl:7
LABEL maintainer="charstnut@gmail.com"

ENV ROOT_VERSION=5.34.36

COPY packages packages

RUN yum update -y
RUN yum install -y yum-conf-epel.noarch
RUN yum install -y $(cat packages)
RUN rm -f /packages

# Clean
RUN yum clean all && rm -rf /var/cache/yum

# Set up pip
RUN pip install --no-cache-dir --upgrade pip setuptools
RUN pip install numpy psycopg2

# Download ROOT
WORKDIR /root
RUN curl -O https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz \
    && mkdir root-${ROOT_VERSION} \
    && tar xzf root_v${ROOT_VERSION}.source.tar.gz -C root-${ROOT_VERSION} --strip-components 1 \
    && rm -rf ${HOME}/root_v${ROOT_VERSION}.source.tar.gz

# Install
WORKDIR /tmp
RUN cmake ${HOME}/root-${ROOT_VERSION}/ -DCMAKE_C_COMPILER=$(which gcc) \
    -DCMAKE_CXX_COMPILER=$(which g++) -Dfail-on-missing=ON \
    -Dfftw3:BOOL=ON -Droofit:BOOL=ON \
    -Dmathmore:BOOL=ON \
    -Dminuit:BOOL=ON \
    -Dminuit2:BOOL=ON \
    -Dgsl_shared:BOOL=ON \
    -Dqt:BOOL=ON \
    -Dpgsql:BOOL=ON \
    -Dbuiltin_afterimage=OFF \
    -Dbuiltin_ftgl=OFF \
    -Dbuiltin_gl2ps=OFF \
    -Dbuiltin_glew=OFF \
    -Dbuiltin_tbb=ON \
    -Dbuiltin_unuran=OFF \
    -Dbuiltin_vdt=ON \
    -Dbuiltin_veccore=ON \
    -Dbuiltin_xrootd=OFF \
    -Dgfal=OFF \
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
    -Dvc=OFF

RUN cmake --build . -- -j$(nproc) \
    && cmake --build . --target install \
    && rm -rf ${HOME}/root-${ROOT_VERSION} /tmp/*

ENV ROOTSYS="/usr/local"
ENV PATH="$ROOTSYS/bin:$PATH"
ENV LD_LIBRARY_PATH="$ROOTSYS/lib:$LD_LIBRARY_PATH"
ENV PYTHONPATH="$ROOTSYS/lib:$PYTHONPATH"
ENV DISPLAY=0
RUN echo ". /usr/local/bin/thisroot.sh" >> ~/.bashrc
RUN /sbin/ldconfig

CMD [ "/bin/bash" ]

# Another way of installing ROOT (in case building fails)
# https://redmine.jlab.org/projects/podd/wiki/ROOT_Installation_Guide
