import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import numpy as np
from PIL import Image

WIDTH = 256
HEIGHT = 256


# ============================================================
# LOAD INPUT IMAGE (REAL PHOTO → 256x256 grayscale)
# ============================================================

def load_input_image(path="input.png"):
    img = Image.open(path).convert("L")  # grayscale
    img = img.resize((WIDTH, HEIGHT), Image.BILINEAR)
    return np.array(img, dtype=np.uint8)


# ============================================================
# OPTIONAL FALLBACK IMAGE (so test never breaks)
# ============================================================

def ensure_input_image():
    try:
        Image.open("input.png")
    except:
        print("input.png not found — generating fallback image")
        fallback = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

        for y in range(HEIGHT):
            for x in range(WIDTH):
                fallback[y, x] = (x + y) % 256

        Image.fromarray(fallback).save("input.png")


# ============================================================
# SAFE READ
# ============================================================

def safe(val):
    try:
        return int(val)
    except:
        return 0


# ============================================================
# SAVE IMAGE
# ============================================================

def save(img, name):
    Image.fromarray(img.astype(np.uint8), mode="L").save(name)


# ============================================================
# RUN FRAME THROUGH DUT
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

    # --------------------------------------------------------
    # Clock
    # --------------------------------------------------------
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # --------------------------------------------------------
    # Reset
    # --------------------------------------------------------
    dut.rst_n.value = 0
    dut.ena.value = 1

    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --------------------------------------------------------
    # Load real image input
    # --------------------------------------------------------
    ensure_input_image()
    img = load_input_image("input.png")

    # Save normalized input (debug reference)
    save(img, "input_normalized.png")

    # --------------------------------------------------------
    # Run DUT in all modes
    # --------------------------------------------------------
    frame0 = await run_frame(dut, 0b00, img)
    save(frame0, "mode0.png")

    frame1 = await run_frame(dut, 0b01, img)
    save(frame1, "mode1.png")

    frame2 = await run_frame(dut, 0b10, img)
    save(frame2, "mode2.png")

    frame3 = await run_frame(dut, 0b11, img)
    save(frame3, "mode3.png")
