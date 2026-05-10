import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import numpy as np
from PIL import Image

WIDTH = 256
HEIGHT = 256


# ============================================================
# INPUT IMAGE
# ============================================================

def generate_test_image():
    img = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

    # solid background
    img[:, :] = 40

    for y in range(HEIGHT):
        for x in range(WIDTH):

            # vertical bright bar
            if 90 < x < 130:
                img[y, x] = 180

            # circle
            dx = x - 160
            dy = y - 120
            if dx*dx + dy*dy < 45*45:
                img[y, x] = 255

            # small dark hole inside circle
            if dx*dx + dy*dy < 20*20:
                img[y, x] = 20

    return img


# ============================================================
# SAFE READ
# ============================================================

def safe(val):
    try:
        return int(val)
    except:
        return 0


# ============================================================
# SAVE
# ============================================================

def save(img, name):
    Image.fromarray(img.astype(np.uint8), mode="L").save(name)


# ============================================================
# RUN FRAME
# ============================================================

async def run_frame(dut, mode, img):

    frame = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

    for y in range(HEIGHT):
        for x in range(WIDTH):

            dut.ui_in.value = mode
            dut.uio_in.value = int(img[y, x])

            await ClockCycles(dut.clk, 1)

            frame[y, x] = safe(dut.uo_out.value)

    return frame


# ============================================================
# TEST
# ============================================================

@cocotb.test()
async def test_pipeline(dut):

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ena.value = 1

    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    img = generate_test_image()

    # SAVE INPUT IMAGE (important for debugging)
    save(img, "input.png")

    frame0 = await run_frame(dut, 0b00, img)
    save(frame0, "mode0.png")

    frame1 = await run_frame(dut, 0b01, img)
    save(frame1, "mode1.png")

    frame2 = await run_frame(dut, 0b10, img)
    save(frame2, "mode2.png")

    frame3 = await run_frame(dut, 0b11, img)
    save(frame3, "mode3.png")
