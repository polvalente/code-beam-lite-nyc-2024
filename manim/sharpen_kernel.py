from manim import *
import numpy as np

class SharpenKernel(Scene):
    def construct(self):
        self.camera.background_color = WHITE
        # 7x7 sharpen kernel: 2*dirac - Gaussian
        kernel = np.array([
            [-0.0000, -0.0002, -0.0011, -0.0018, -0.0011, -0.0002, -0.0000],
            [-0.0002, -0.0029, -0.0131, -0.0215, -0.0131, -0.0029, -0.0002],
            [-0.0011, -0.0131, -0.0586, -0.0965, -0.0586, -0.0131, -0.0011],
            [-0.0018, -0.0215, -0.0965, 1.8408, -0.0965, -0.0215, -0.0018],
            [-0.0011, -0.0131, -0.0586, -0.0965, -0.0586, -0.0131, -0.0011],
            [-0.0002, -0.0029, -0.0131, -0.0215, -0.0131, -0.0029, -0.0002],
            [-0.0000, -0.0002, -0.0011, -0.0018, -0.0011, -0.0002, -0.0000],
        ])
        latex_rows = [
            " & ".join(f"{x:.4f}" for x in row) for row in kernel
        ]
        latex_matrix = r"\begin{bmatrix}" + r" \\ ".join(latex_rows) + r"\end{bmatrix}"
        mobj = MathTex(latex_matrix, color=BLACK, font_size=48)
        mobj.move_to(ORIGIN).set_color(BLACK).scale(0.8)
        self.add(mobj)