# Using scientific linux as base
FROM sl:7
LABEL maintainer="charstnut@gmail.com"

ENV ROOT_VERSION=5.34.36

RUN yum -y install epel-release 
RUN yum -y install gcc-c++ bzip2 git libpng libjpeg \
    python-devel libSM libX11 libXext libXpm libXft gsl-devel python-pip make cmake3 \
    && yum -y clean all
RUN pip install --no-cache-dir --upgrade pip setuptools
RUN pip install --no-cache-dir numpy jupyter

# Hopefully the centos7 image works
RUN curl -o /var/tmp/root.tar.gz https://root.cern.ch/download/root_v${ROOT_VERSION}.Linux-centos7-x86_64-gcc4.8.tar.gz 
RUN tar xzf /var/tmp/root.tar.gz -C /opt && rm /var/tmp/root.tar.gz

# Set ROOT environment
ENV ROOTSYS         "/opt/root"
ENV PATH            "$ROOTSYS/bin:$ROOTSYS/bin/bin:$PATH"
ENV LD_LIBRARY_PATH "$ROOTSYS/lib:$LD_LIBRARY_PATH"
ENV PYTHONPATH      "$ROOTSYS/lib:$PYTHONPATH"
ENV DISPLAY=0
RUN echo ". /opt/root/bin/thisroot.sh" >> ~/.bashrc