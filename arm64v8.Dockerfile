FROM alpine AS qemu

# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-aarch64.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1


FROM debian:buster AS build
ARG NUM_BUILD_PROC=1

# Add QEMU
COPY --from=qemu qemu-aarch64-static /usr/bin

RUN apt-get update && dpkg --add-architecture arm64

RUN apt-get update && apt-get install -y -q --no-install-recommends \
  cmake \
  pkg-config \
  git \
  unzip \
  wget \
  python3-dev \
  python3-numpy \ 
  libpython3-dev:arm64 \
  libgtk2.0-dev:arm64 \
  # libgtk-3-dev:arm64 \
  # qtdeclarative5-dev:arm64 \
  # qt5-default \
  # libcanberra-gtk3-dev:arm64 \
  zlib1g-dev:arm64 \
  libturbojpeg0-dev:arm64 \
  libpng++-dev:arm64 \
  libavcodec-dev:arm64 \libavformat-dev:arm64 libswscale-dev:arm64 libv4l-dev:arm64 \
  libxvidcore-dev:arm64 libx264-dev:arm64 \
  libprotobuf-dev:arm64 \
  crossbuild-essential-arm64 \
  g++-arm-linux-gnueabi \
  g++-arm-linux-gnueabihf \
  cython3 \
  libusb-1.0-0-dev:arm64 \
  ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG DLDT_DIR=/dldt
# ADD dldt/ ${DLDT_DIR}/
RUN [ ! -d ${DLDT_DIR}/inference-engine ] && rm -rf ${DLDT_DIR} && git clone --recursive --depth=1 -b 2019_R3 https://github.com/opencv/dldt.git ${DLDT_DIR} || echo skipped

WORKDIR ${DLDT_DIR}/inference-engine/build
RUN sed -i 's/-Werror -Werror=return-type/-Werror=return-type/g' ../cmake/os_flags.cmake
RUN cmake \
  -D CMAKE_TOOLCHAIN_FILE=../cmake/arm64.toolchain.cmake \
  -D ENABLE_PYTHON=OFF \
  -D PYTHON_EXECUTABLE=$(which python3)\
  -D ENABLE_CLDNN=OFF \
  -D ENABLE_MKL_DNN=OFF \
  -D ENABLE_GNA=OFF \
  -D ENABLE_SSE42=OFF \
  -D ENABLE_TESTS=OFF \
  -D ENABLE_SAMPLES=OFF \
  -D THREADING=SEQ \
  -D CMAKE_BUILD_TYPE=Release \
  ..
RUN make -j${NUM_BUILD_PROC}

ENV OpenCV_DIR=/opt/opencv-4.1.1
ENV InferenceEngine_DIR=/dldt/inference-engine/build/share
WORKDIR /opencv
RUN  wget -nv https://github.com/opencv/opencv/archive/4.1.1.tar.gz && tar -xvf 4.1.1.tar.gz > /dev/null
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig

WORKDIR /opencv/opencv-4.1.1/build
RUN cmake \
  -D _ARCH=arm64 \
  -D WITH_WEBP=OFF \
  -D WITH_VTK=OFF \
  -D WITH_TIFF=OFF \
  -D WITH_PNG=ON \
  -D WITH_ZLIB=ON \
  -D WITH_TBB=OFF \
  -D WITH_QUIRC=OFF \
  -D WITH_QT=OFF \
  -D WITH_PROTOBUF=ON \
  -D WITH_OPENVX=OFF \
  -D WITH_OPENEXR=OFF \
  -D WITH_OPENCLAMDFFT=OFF \
  -D WITH_OPENCLAMDBLAS=OFF \
  -D WITH_OPENCL=OFF \
  -D WITH_MFX=OFF \
  -D WITH_MATLAB=OFF \
  -D WITH_LAPACK=OFF \
  -D WITH_JASPER=OFF \
  -D WITH_IPP=OFF \
  -D WITH_INF_ENGINE=ON \
  -D WITH_GTK_2_X=ON \
  # -D WITH_GTK=ON \
  -D WITH_GSTREAMER=OFF \
  -D WITH_GPHOTO2=OFF \
  -D WITH_EIGEN=OFF \
  -D WITH_CUDA=OFF \
  -D WITH_CAROTENE=OFF \
  -D WITH_1394=OFF \
  -D VIDEOIO_PLUGIN_LIST=ffmpeg \
  -D PYTHON3_PACKAGES_PATH=${OpenCV_DIR}/python/python3 \
  -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/lib/python3/dist-packages/numpy/core/include \
  # -D PYTHON3_LIMITED_API=ON \
  -D PYTHON3_LIBRARIES=/usr/lib/aarch64-linux-gnu/libpython3.7m.so \
  -D PYTHON3_INCLUDE_PATH=/usr/include/python3.7m \
  -D PKG_CONFIG_EXECUTABLE=/usr/bin/aarch64-linux-gnu-pkg-config \
  -D OPENCV_SKIP_PYTHON_LOADER=ON \
  -D OPENCV_SKIP_PKGCONFIG_GENERATION=ON \
  -D OPENCV_SKIP_CMAKE_ROOT_CONFIG=ON \
  -D OPENCV_SAMPLES_SRC_INSTALL_PATH=samples \
  -D OPENCV_OTHER_INSTALL_PATH=etc \
  -D OPENCV_LICENSES_INSTALL_PATH=etc/licenses \
  -D OPENCV_LIB_INSTALL_PATH=lib \
  -D OPENCV_INSTALL_FFMPEG_DOWNLOAD_SCRIPT=ON \
  -D OPENCV_INCLUDE_INSTALL_PATH=include \
  -D OPENCV_GENERATE_SETUPVARS=OFF \
  -D OPENCV_ENABLE_PKG_CONFIG=ON \
  -D OPENCV_DOC_INSTALL_PATH=doc \
  -D OPENCV_CONFIG_INSTALL_PATH=cmake \
  -D OPENCV_BIN_INSTALL_PATH=bin \
  -D OPENCV_3P_LIB_INSTALL_PATH=3rdparty \
  -D InferenceEngine_DIR=/dldt/inference-engine/build/share \
  -D INF_ENGINE_LIB_DIRS="/dldt/inference-engine/bin/aarch64/Release/lib/" \ 
  -D INF_ENGINE_INCLUDE_DIRS="/dldt/inference-engine/include" \
  -D CMAKE_FIND_ROOT_PATH="/dldt" \
  -D INSTALL_TESTS=ON \
  -D INSTALL_PYTHON_EXAMPLES=ON \
  -D INSTALL_PDB=ON \
  -D INSTALL_C_EXAMPLES=ON \
  # -D INF_ENGINE_RELEASE=2019030000 \
  # -D ENABLE_VFPV3=ON \ # Has no effect on arm64 : https://github.com/opencv/opencv/issues/13114
  -D ENABLE_PRECOMPILED_HEADERS=OFF \
  # -D ENABLE_NEON=ON \
  -D ENABLE_CXX11=ON \
  -D ENABLE_CONFIG_VERIFICATION=ON \
  -D ENABLE_BUILD_HARDENING=ON \
  # -D CPU_BASELINE=NEON \
  -D CMAKE_USE_RELATIVE_PATHS=ON \
  -D CMAKE_TOOLCHAIN_FILE=../platforms/linux/aarch64-gnu.toolchain.cmake \
  -D CMAKE_SKIP_INSTALL_RPATH=ON \
  # -D CMAKE_INSTALL_PREFIX=install \
  -D CMAKE_INSTALL_PREFIX=${OpenCV_DIR} \
  # -D CMAKE_FIND_ROOT_PATH=/home/jenkins/workspace/OpenCV/OpenVINO/build/ie \
  -D CMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
  -D CMAKE_BUILD_TYPE=Release \
  -D BUILD_opencv_world=OFF \
  -D BUILD_opencv_python3=ON \
  -D BUILD_opencv_python2=OFF \
  -D BUILD_opencv_java=OFF \
  -D BUILD_opencv_apps=ON \
  -D BUILD_ZLIB=OFF \
  -D BUILD_WEBP=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_TBB=OFF \
  -D BUILD_PROTOBUF=ON \
  -D BUILD_PNG=OFF \
  -D BUILD_OPENEXR=OFF \
  -D BUILD_OPENCV_PYTHON3=ON \
  -D BUILD_JPEG=OFF \
  -D BUILD_JAVA=OFF \
  -D BUILD_JASPER=OFF \
  -D BUILD_INFO_SKIP_EXTRA_MODULES=ON \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_DOCS=OFF \
  -D BUILD_APPS_LIST=version \
  ..
RUN make -j${NUM_BUILD_PROC} && make install

# Rebuild with ENABLE_PYTHON=ON (FIXME)
WORKDIR ${DLDT_DIR}/inference-engine/build
RUN sed -i 's/-Werror -Werror=return-type/-Werror=return-type/g' ../cmake/os_flags.cmake
RUN cmake \
  -D CMAKE_TOOLCHAIN_FILE=../cmake/arm64.toolchain.cmake \
  -D ENABLE_PYTHON=ON \
  -D PYTHON_EXECUTABLE=$(which python3)\
  -D ENABLE_CLDNN=OFF \
  -D ENABLE_MKL_DNN=OFF \
  -D ENABLE_GNA=OFF \
  -D ENABLE_SSE42=OFF \
  -D ENABLE_TESTS=OFF \
  -D ENABLE_SAMPLES=ON \
  -D THREADING=SEQ \
  -D CMAKE_BUILD_TYPE=Release \
  ..
RUN make -j${NUM_BUILD_PROC}


FROM arm64v8/debian:buster AS runtime

# Add QEMU
COPY --from=qemu qemu-aarch64-static /usr/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  usbutils \
  libgtk2.0 \
  python3-minimal \
  python3-numpy \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# libgtk-3-0   python3-minimal   python3-numpy libcanberra-gtk3-0 libjpeg62-turbo libpng16-16 libavcodec58 libavformat58 libswscale5 

ENV OpenCV_DIR=/opt/opencv-4.1.1
COPY --from=build /dldt/inference-engine/bin/aarch64/Release/ /opt/openvino
COPY --from=build /dldt/inference-engine/bin/aarch64/Release/lib/python_api/python3.7/openvino/ /usr/local/lib/openvino/
COPY --from=build ${OpenCV_DIR} /opt/opencv
COPY --from=build ${OpenCV_DIR}/python/python3/cv2.*.so /usr/local/lib/cv2.abi3.so
ENV LD_LIBRARY_PATH=/opt/opencv/lib:/opt/openvino/lib:/usr/local/lib
ENV PYTHONPATH=/usr/local/lib