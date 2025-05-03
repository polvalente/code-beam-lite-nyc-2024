from manim import *
import numpy as np
import os

class KernelMatrix(Scene):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        kernel_type = os.environ.get("KERNEL_TYPE", "uniform")
        if kernel_type == "gaussian":
            from scipy.ndimage import gaussian_filter
            k = np.zeros((7,7)); k[3,3]=1; g = gaussian_filter(k, sigma=1.0); g /= g.sum()
            self.kernel = g
        else:
            self.kernel = np.ones((7, 7)) / 49

    def construct(self):
        self.camera.background_color = WHITE
        # Format the kernel as a LaTeX bmatrix string with 4 decimal places
        latex_rows = [
            " & ".join(f"{x:.4f}" for x in row) for row in self.kernel
        ]
        latex_matrix = r"\begin{bmatrix}" + r" \\ ".join(latex_rows) + r"\end{bmatrix}"
        mobj = MathTex(latex_matrix, color=BLACK, font_size=48)
        mobj.move_to(ORIGIN).set_color(BLACK)
        self.add(mobj)

if __name__ == "__main__":
    import sys
    import numpy as np
    from scipy.ndimage import gaussian_filter

    if len(sys.argv) > 1 and sys.argv[1] == "gaussian":
        k = np.zeros((7,7)); k[3,3]=1; g = gaussian_filter(k, sigma=1.0); g /= g.sum()
        scene = KernelMatrix()
    else:
        scene = KernelMatrix()
    scene.render()