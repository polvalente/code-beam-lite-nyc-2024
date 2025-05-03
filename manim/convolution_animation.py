from manim import *
import numpy as np

class ConvolutionAnimation(Scene):
    def construct(self):
        # 4x4 matrix
        matrix = np.arange(1, 17).reshape(4, 4)
        mobj = IntegerTable(matrix, include_outer_lines=True).scale(1.2)
        mobj.to_edge(LEFT)

        # 2x2 kernel
        kernel = np.array([[-1, 1], [1, -1]])
        kobj = IntegerTable(kernel, include_outer_lines=True, h_buff=0.8, v_buff=0.8).scale(1.2)
        kobj.set_fill(BLACK, opacity=0.2)
        kobj.set_stroke(RED, width=4)

        # Animation: slide kernel over matrix with 0-padding
        positions = [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1), (1, 2),
            (2, 0), (2, 1), (2, 2)
        ]
        start = mobj.get_cell((1, 1)).get_center() + LEFT*0.6 + UP*0.6
        kobj.move_to(start)
        self.add(mobj, kobj)
        self.wait(0.5)
        for (i, j) in positions:
            target = mobj.get_cell((i+1, j+1)).get_center() + LEFT*0.6 + UP*0.6
            self.play(kobj.animate.move_to(target), run_time=1.5)
            self.wait(0.2)