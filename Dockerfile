# Using scientific linux as base
FROM sl:7
LABEL maintainer="charstnut@gmail.com"

ENV ROOT_VERSION=5.34.36

COPY packages packages

RUN yum update -y
RUN yum remove -y systemd
RUN yum install -y yum-conf-epel.noarch
RUN yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
RUN yum install -y $(cat packages)
ENV PATH=$PATH:/usr/pgsql-9.6/bin/

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
RUN cmake ${HOME}/root-${ROOT_VERSION}/ \
    -DCMAKE_C_COMPILER=$(which gcc) -DCMAKE_CXX_COMPILER=$(which g++) -Dfftw3:BOOL=ON -DPYTHON_EXECUTABLE=$(which python) \
    -DPYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -DPYTHON_LIBRARY=$(python -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
    -Droofit:BOOL=ON -Dmathmore:BOOL=ON -Dminuit:BOOL=ON -Dminuit2:BOOL=ON -Dgsl_shared:BOOL=ON -Dqt:BOOL=ON -Dpgsql:BOOL=ON

RUN cmake --build . -- -j$(nproc)
RUN cmake --build . --target install \
    && rm -rf ${HOME}/root-${ROOT_VERSION} /tmp/*

ENV ROOTSYS         "/usr/local"
ENV PATH            "$ROOTSYS/bin:$PATH"
ENV LD_LIBRARY_PATH "$ROOTSYS/lib:$LD_LIBRARY_PATH"
ENV PYTHONPATH      "$ROOTSYS/lib:$PYTHONPATH"
ENV DISPLAY=0
RUN echo ". /usr/local/bin/thisroot.sh" >> ~/.bashrc
WORKDIR /root

# # TODO: Get latest tini version automatically (see anaconda docker)
# # ENV TINI_VERSION v0.18.0
# # ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
# # RUN chmod +x /usr/bin/tini

CMD [ "/bin/bash" ]

# # Another way of installing ROOT (in case building fails)
# # https://redmine.jlab.org/projects/podd/wiki/ROOT_Installation_Guide
