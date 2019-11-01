import spidev

# Borrowd from https://github.com/joosteto/ws2812-spi/issues/6


class WS2812B():

    def __init__(self, n_led, spi_bus=(0, 0)):
        self.spi_bus = spi_bus
        self.n_led = n_led
        self.spi = self._init_spi()

    def _init_spi(self):
        # Initialize SPI with the correct frequency
        spi = spidev.SpiDev()
        spi.open(*(self.spi_bus))
        spi.max_speed_hz = int(4/1.05e-6)
        spi.mode = 0b00
        return spi

    def get_n_led(self):
        return self.n_led

    def get_colors_arr(self):
        return [[0, 0, 0]]*self.n_led

    def off(self):
        colors = self.get_colors_arr()
        self.show(colors)

    def show(self, colors):
        # Optimized version of the `write2812_pylist4` function at:
        # https://github.com/joosteto/ws2812-spi/blob/master/ws2812.py
        # with this fix (0x00 at the beginning): https://github.com/joosteto/ws2812-spi/issues/2
        tx = [0x00]*5 + [
            ((byte >> (2 * ibit + 1)) & 1) * 0x60 +
            ((byte >> (2 * ibit + 0)) & 1) * 0x06 +
            0x88
            for rgb in colors
            for byte in (rgb[1], rgb[0], rgb[2])  # the LED strip is GRB
            for ibit in range(3, -1, -1)
        ]

        # Using xfer() or xfer2() in place of writebytes() causes the LEDs to flicker after the 5th one
        # reports of this bug:
        # 1) https://github.com/doceme/py-spidev/issues/72
        # 2) https://github.com/joosteto/ws2812-spi/issues/6
        self.spi.writebytes(tx)
