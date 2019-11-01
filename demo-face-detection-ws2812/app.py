#! /usr/bin/env python3
from ws2812b import WS2812B
import sys
import cv2
import numpy as np
import argparse
import time

# init argument parser
parser = argparse.ArgumentParser(description='Face detection using \
                        Intel Movidius NCU')
parser.add_argument('-m', '--model', metavar='DNN_MODEL',
                    type=str, default="models/face-detection-retail-0004", help='Model base path. Default = "models/face-detection-retail-0004".')
parser.add_argument('-s', '--source', metavar='CAMERA_SOURCE',
                    type=int, default=0, help='V4L2 Camera source. Default = 0.')
parser.add_argument('-c', '--cap-res', metavar='CAMERA_CAPTURE_RESOLUTION',
                    type=int, nargs=2, default=(640, 480), help='Camera capture resolution. Default = (640, 480).')
parser.add_argument('-l', '--led-num', metavar='LED_NUM',
                    type=int, default=12, help='Number of ws2812 LEDs. Default = 12.')
parser.add_argument('-b', '--spi-bus', metavar='SPI_BUS',
                    type=int, nargs=2, default=(0, 0), help='SPI bus id to use. Default = (0, 0) = /dev/spidev0.0.')
ARGS = parser.parse_args()

# init led
N_LED = ARGS.led_num
led = WS2812B(N_LED, spi_bus=ARGS.spi_bus)
led.off()

# load model
model_base_path = ARGS.model
net = cv2.dnn.readNet('{}.xml'.format(model_base_path),
                      '{}.bin'.format(model_base_path))
net.setPreferableTarget(cv2.dnn.DNN_TARGET_MYRIAD)


def preprocess_image(img, input_shape):
    global ARGS
    # Get input shapes
    n = input_shape[0]
    c = input_shape[1]
    h = input_shape[2]
    w = input_shape[3]
    # Image preprocessing
    # img = cv2.flip(img, 1)
    img = cv2.resize(img, tuple((w, h)))
    img = img.astype(np.float32)

    transposed_img = np.transpose(img, (2, 0, 1))  # C H W
    reshaped_img = transposed_img.reshape((n, c, h, w))

    return reshaped_img


def perform_inference(img):
    start_time = time.time()
    net.setInput(img)
    output = net.forward()
    end_time = time.time()

    return output, end_time - start_time


def main():
    # Set the camera capture properties
    cap = cv2.VideoCapture(ARGS.source)
    cap.set(cv2.CAP_PROP_FPS, 30)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, ARGS.cap_res[0])
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, ARGS.cap_res[1])
    CAM_W = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
    CAM_H = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
    print("CAM: WxH={}x{} FPS={}".format(CAM_W, CAM_H, cap.get(cv2.CAP_PROP_FPS)))

    frame_count = 0
    elapsed_time = 0
    fps = 0
    prev_time = time.time()
    input_shape = (1, 3, 300, 300)  # FIXME: infer from the loaded model

    try:
        while (True):
            # Read image from camera, get camera width and height
            start = time.time()
            ret, img = cap.read()
            # print("cap_fps: {:.2f}".format(1/(time.time()-start)))

            frame_count += 1

            # Preprocess the image
            start = time.time()
            input_img = preprocess_image(img, input_shape)
            print("pp_fps: {:.2f}".format(1/(time.time()-start)))

            # Perform the inference and get the results
            res, e_time = perform_inference(input_img)
            probs = np.array(res[0][0])

            # calculate FPS
            elapsed_time = elapsed_time + e_time
            fps = frame_count / elapsed_time
            fps_current = 1/e_time

            # parse results
            top_result = probs[0]
            prob = top_result[2]
            width = top_result[5] - top_result[3]
            height = top_result[6] - top_result[4]
            fsize = (width + height)/2
            print("top_result: {}".format(top_result))

            # control LED
            cols = led.get_colors_arr()
            if prob > 0.2:
                lit_led = min(int(fsize * 2 * N_LED), N_LED)
                for i in range(lit_led):
                    cols[i] = [0, int(prob * 20), int(prob * 10)]
            led.show(cols)

            # show FPS
            now = time.time()
            print("inference_fps(mean):{:.2f}, inference_fps: {:.2f}, total_fps: {:.2f}".format(fps, fps_current, 1/(now - prev_time)))
            prev_time = now

    except KeyboardInterrupt:
        # Cleanup
        cap.release()
        print('Finished.')


if __name__ == '__main__':
    sys.exit(main())
