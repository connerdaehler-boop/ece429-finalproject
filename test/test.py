import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import numpy as np
from PIL import Image

WIDTH = 256
HEIGHT = 256


def save_frame(frame, filename):
    img = Image.fromarray(frame.astype(np.uint8), mode="L")
    img.save(filename)


async def capture_frame(dut, mode_bits):
    """
    mode_bits = 0,1,2,3
    ui_in format:
        [7:2] unused
        [1:0] mode
        [2] freeze
        [3] invert
    """

    dut.ui_in.value = mode_bits  # freeze=0, invert=0

    frame = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

    x = 0
    y = 0

    for _ in range(WIDTH * HEIGHT):

        await ClockCycles(dut.clk, 1)

        pixel = int(dut.uo_out.value)
        frame[y, x] = pixel

        x += 1
        if x == WIDTH:
            x = 0
            y += 1

    return frame


@cocotb.test()
async def test_procedural_graphics_image(dut):

    dut._log.info("Starting procedural graphics image test")

    # Clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.ui_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # ============================================================
    # MODE 0
    # ============================================================
    frame0 = await capture_frame(dut, 0b00)
    save_frame(frame0, "mode0.png")
    dut._log.info("Saved mode0.png")

    # ============================================================
    # MODE 1
    # ============================================================
    frame1 = await capture_frame(dut, 0b01)
    save_frame(frame1, "mode1.png")
    dut._log.info("Saved mode1.png")

    # ============================================================
    # MODE 2
    # ============================================================
    frame2 = await capture_frame(dut, 0b10)
    save_frame(frame2, "mode2.png")
    dut._log.info("Saved mode2.png")

    # ============================================================
    # MODE 3
    # ============================================================
    frame3 = await capture_frame(dut, 0b11)
    save_frame(frame3, "mode3.png")
    dut._log.info("Saved mode3.png")
