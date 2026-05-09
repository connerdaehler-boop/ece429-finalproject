<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a procedural graphics generator ASIC that produces grayscale pixel values in real time using simple arithmetic logic. Essentially, this is a single-pixel, scan-based fragment shader engine.
## How to test

The design is tested using a cocotb-based Python testbench that reconstructs full images from the pixel stream. It creates 4 output images for each mode

## External hardware

None is required
