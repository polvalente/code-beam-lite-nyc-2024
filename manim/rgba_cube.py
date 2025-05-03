from manim import *

class RGBACube(Scene):
    def construct(self):
        # Define soft colors for RGBA
        soft_red = "#ffb3b3"
        soft_green = "#b3ffb3"
        soft_blue = "#b3b3ff"
        soft_alpha = "#dddddd"

        # Create 4 transparent cubes for RGBA layers
        cube_r = Cube(side_length=2, fill_color=soft_red, fill_opacity=0.7, stroke_color=BLACK).shift(LEFT*0.3+UP*0.3+OUT*0.3)
        cube_g = Cube(side_length=2, fill_color=soft_green, fill_opacity=0.7, stroke_color=BLACK).shift(RIGHT*0.3+UP*0.3+OUT*0.3)
        cube_b = Cube(side_length=2, fill_color=soft_blue, fill_opacity=0.7, stroke_color=BLACK).shift(LEFT*0.3+DOWN*0.3+IN*0.3)
        cube_a = Cube(side_length=2, fill_color=soft_alpha, fill_opacity=0.5, stroke_color=BLACK).shift(RIGHT*0.3+DOWN*0.3+IN*0.3)

        # Group and rotate to show 3 faces
        group = VGroup(cube_r, cube_g, cube_b, cube_a)
        group.rotate(PI/6, axis=RIGHT)
        group.rotate(-PI/6, axis=UP)

        # Add RGBA labels
        label_r = Text("R", color=RED).next_to(cube_r, OUT)
        label_g = Text("G", color=GREEN).next_to(cube_g, OUT)
        label_b = Text("B", color=BLUE).next_to(cube_b, OUT)
        label_a = Text("A", color=BLACK).next_to(cube_a, OUT)

        self.add(group, label_r, label_g, label_b, label_a)