from manim import *
import numpy as np

class SharpenKernel(Scene):
    def construct(self):
        # Placeholder 3x3 kernel, will be replaced with 7x7 from numpy
        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
        kobj = IntegerTable(kernel, include_outer_lines=True).scale(2)
        self.add(kobj)