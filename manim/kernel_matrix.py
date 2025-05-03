from manim import *
import numpy as np

class KernelMatrix(Scene):
    def construct(self):
        # Placeholder 7x7 kernel, will be replaced with numpy-generated values
        kernel = np.ones((7, 7))
        kobj = IntegerTable(kernel, include_outer_lines=True, element_to_mobject_config={"num_decimal_places": 2}).scale(1.2)
        self.add(kobj)