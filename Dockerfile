FROM alpine:3.6
MAINTAINER Jorge S. Mendes de Jesus <jorge.dejesus@geocat.net>


ARG ROOTDIR=/usr/local/
ARG GDAL_VERSION=2.2.4
ARG PROCESSOR_N=6
ARG OPENJPEG_VERSION=2.2.0

# Load assets
WORKDIR $ROOTDIR/

ADD https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz $ROOTDIR/src/openjpeg-${OPENJPEG_VERSION}.tar.gz


RUN apk update && apk add --no-cache \
    git \
    gcc \
    bash \
    openssh \
    musl-dev  \
    python3 \
    python3-dev \
    linux-headers \
    g++ \
    libstdc++ \
    make \
    cmake \
    openssl \
    swig  

RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    geos \
    geos-dev



# Compile and install OpenJPEG
RUN cd src && tar -xvf openjpeg-${OPENJPEG_VERSION}.tar.gz && cd openjpeg-${OPENJPEG_VERSION}/ \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$ROOTDIR \
    && make && make install && make clean \
&& cd $ROOTDIR && rm -Rf src/openjpeg*


RUN wget -O ${ROOTDIR}/ERDAS-ECW_JPEG_2000_SDK-5.4.0.tar.gz "https://eos.geocat.net/owncloud/public.php?service=files&t=590b480a045288b3dbd99a28470ea984&download" 

RUN tar -xvf ${ROOTDIR}/ERDAS-ECW_JPEG_2000_SDK-5.4.0.tar.gz
#ADD  ERDAS-ECW_JPEG_2000_SDK-5.4.0.tar.gz $ROOTDIR/

RUN cp -r $ROOTDIR/ERDAS-ECW_JPEG_2000_SDK-5.4.0/Desktop_Read-Only $ROOTDIR/hexagon
#RUN ldconfig $ROOTDIR/hexagon

RUN ln -s $ROOTDIR/hexagon/lib/x64/release/libNCSEcw.so /usr/local/lib/libNCSEcw.so
RUN ldconfig /usr/local/lib
#To check that things are ok and in place
RUN ls /usr/local/lib/*

CMD ash 
# Install GDAL
RUN wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz -O /tmp/gdal.tar.gz && \
	tar xzf /tmp/gdal.tar.gz -C /tmp && \
	cd /tmp/gdal-${GDAL_VERSION} && \
        LDFLAGS="-s" CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"  ./configure  --with-ecw=$ROOTDIR/hexagon  --with-geos=yes \
	&& make -j ${PROCESSOR_N} && make install

RUN cd /tmp/gdal-${GDAL_VERSION}/swig/python \
	&& python3 setup.py install

RUN rm -rf /var/cache/apk/*
 

CMD gdalinfo --version && gdalinfo --formats && ogrinfo --formats
