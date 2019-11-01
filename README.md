# openvino-opencv-docker
Containerized [OpenVINO Toolkit (+OpenCV)](https://github.com/opencv/dldt) to use [Intel Movidius Neural Compute Stick](https://www.movidius.com/) especially on `arm64v8` based SBCs (such as Orange Pi + [Armbian](https://armbian.com)).  
This might be also useful if you want just OpenCV4 w/o any HW DNN accelerator.

## Images
All the images are based on [`debian:buster`](https://hub.docker.com/_/debian). See also [Getting started](#getting-started).

```yml
  image: registry.gitlab.com/likeablob/openvino-opencv-docker:master-runtime-arm64v8
```

```yml
  image: registry.gitlab.com/likeablob/openvino-opencv-docker:master-runtime-x86_64
```

### Tagging rule
- `${branch}-${type}-${arch}`
  - `${branch}`: A branch name. `master` or `devel`.
  - `${type}`: `runtime` or `build`.
    - `runtime`: A image containing the OpenVINO and OpenCV runtime libs.  
    - `build`: A image to build OpenVINO and OpenCV. 
  - `${arch}`: `arm64v8` or `x86_64`. (The `arm64v8` images can be run on `x86_64` system thanks to qemu-aarch64-static.)

## Getting started
### [demo-face-detection-x11](./demo-face-detection-x11)
A simple face detection demo written in Python with real-time visualization on the display.  
The DNN model used is [opencv/open_model_zoo/face-detection-retail-0004](https://github.com/opencv/open_model_zoo/blob/master/models/intel/face-detection-retail-0004/description/face-detection-retail-0004.md).
```bash
git clone https://github.com/likeablob/openvino-opencv-docker
cd openvino-opencv-docker/demo-face-detection-x11
./download_model.sh
T_ARCH="arm64v8" docker-compose run --rm app
T_ARCH="x86_64" docker-compose run --rm app
```

### [demo-face-detection-ws2812](./demo-face-detection-ws2812)
A simple face detection demo written in Python.
Utilize a `ws2812` LED strip to visualize the result. (`ws2812` is controlled via SPI bus).  
The DNN model used is [opencv/open_model_zoo/face-detection-retail-0004](https://github.com/opencv/open_model_zoo/blob/master/models/intel/face-detection-retail-0004/description/face-detection-retail-0004.md).

(*Note that currently this demo can only be run on `arm64v8` systems.)
```bash
git clone https://github.com/likeablob/openvino-opencv-docker
cd openvino-opencv-docker/demo-face-detection-ws2812
./download_model.sh
docker-compose run --rm app
# CAM: WxH=640.0x480.0 FPS=30.0
# ...
# top_result: [0.         1.         0.7441406  0.32885742 0.5986328  0.4699707 0.8642578 ]
# inference_fps(mean):14.38, inference_fps: 25.38, total_fps: 19.93
# ...
```
### Appendix 1: Installing Docker on Armbian
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
sudo usermod -aG docker $USER

sudo apt install -y gnupg2 pass docker-compose
```

### Appendix 2: Enabling SPI on Armbian 
```bash
sudo vi /boot/armbianEnv.txt
+ overlays=spi-spidev
+ param_spidev_spi_bus=0 # param_spidev_spi_bus=1 for OPi-Zero*
sudo shutdown -r now

ls /dev/spidev*
# /dev/spidev0.0
# `docker-compose run --rm app -b 1 0` to use /dev/spidev1.0
```
|  Orange Pi Lite2  | WS2812 |
| :---------------: | :----: |
| Pin 19(SPI0_MOSI) |   DI   |
|    Pin 25(GND)    |  GND   |
|    Pin 1(3.3V)    |  3.3V  |
