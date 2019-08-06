# Using scientific linux as base
FROM sl:7
LABEL maintainer="charstnut@gmail.com"

ENV ROOT_VERSION=5.34.36

COPY packages packages

# Install ROOT dependencies and some additional packages
RUN yum update -y \
    && yum install -y yum-conf-epel.noarch \
    && yum install -y $(cat packages) \
    && rm -f /packages

### PSQL(9.6) ###
RUN yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
    && yum install -y postgresql96 postgresql96-devel
ENV PATH=/usr/pgsql-9.6/bin:$PATH \
    LD_LIBRARY_PATH=/usr/pgsql-9.6/lib:$LD_LIBRARY_PATH

# Clean
RUN yum clean all && rm -rf /var/cache/yum && rm -rf /usr/tmp/*

# Set up pip (numpy + psycopg2)
RUN pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache-dir numpy psycopg2

# Download ROOT
WORKDIR /root
RUN curl -O https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz \
    && mkdir root-${ROOT_VERSION} \
    && tar xzf root_v${ROOT_VERSION}.source.tar.gz -C root-${ROOT_VERSION} --strip-components 1 \
    && rm -rf ${HOME}/root_v${ROOT_VERSION}.source.tar.gz

# # Install
WORKDIR /tmp
RUN mkdir -p /opt/root \
    && cmake ${HOME}/root-${ROOT_VERSION}/ -DCMAKE_C_COMPILER=$(which gcc) \
    -DCMAKE_CXX_COMPILER=$(which g++) \
    -DCMAKE_INSTALL_PREFIX=/opt/root \
    -Dfail-on-missing=ON \
    -Dfftw3:BOOL=ON -Droofit:BOOL=ON \
    -Dmathmore:BOOL=ON \
    -Dminuit:BOOL=ON \
    -Dminuit2:BOOL=ON \
    -Dgsl_shared:BOOL=ON \
    -Dqt:BOOL=ON \
    -Dpgsql:BOOL=ON \
    -DPOSTGRESQL_INCLUDE_DIR=/usr/pgsql-9.6/include \
    -DPOSTGRESQL_LIBRARIES=/usr/pgsql-9.6/lib/libpq.so \
    -Dbuiltin_afterimage=OFF \
    -Dbuiltin_ftgl=OFF \
    -Dbuiltin_gl2ps=OFF \
    -Dbuiltin_glew=OFF \
    -Dbuiltin_tbb=ON \
    -Dbuiltin_unuran=OFF \
    -Dbuiltin_vdt=ON \
    -Dbuiltin_veccore=ON \
    -Dbuiltin_xrootd=OFF \
    -Dbonjour=OFF \
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

ENV ROOTSYS="/opt/root"
ENV PATH="$ROOTSYS/bin:$PATH" \
    LD_LIBRARY_PATH="$ROOTSYS/lib:$LD_LIBRARY_PATH" \
    PYTHONPATH="$ROOTSYS/lib:$PYTHONPATH" \
    DISPLAY=0
RUN echo ". ${ROOTSYS}/bin/thisroot.sh" >> ~/.bashrc

WORKDIR /root
RUN /sbin/ldconfig

CMD [ "/bin/bash" ]

# Another way of installing ROOT (in case building fails)
# https://redmine.jlab.org/projects/podd/wiki/ROOT_Installation_Guide
