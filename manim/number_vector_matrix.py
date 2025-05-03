from manim import *

class NumberVectorMatrix(Scene):
    def construct(self):
        # Number
        number = MathTex("3.14").scale(2).to_edge(UP)
        # Vector
        vector = MathTex(r"\begin{bmatrix}1 \\ 2 \\ 3\end{bmatrix}").scale(2).next_to(number, DOWN, buff=1)
        # Matrix
        matrix = MathTex(r"\begin{bmatrix}1 & 2 \\ 3 & 4\end{bmatrix}").scale(2).next_to(vector, DOWN, buff=1)

        self.add(number, vector, matrix)