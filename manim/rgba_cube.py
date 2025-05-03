from manim import *
from manim.mobject.three_d.three_dimensions import Prism

class RGBACube(ThreeDScene):
    def construct(self):
        self.camera.background_color = WHITE
        self.set_camera_orientation(phi=-PI/8, theta=-PI/2)
        self.camera.set_zoom(0.8)
        # Define soft colors for RGBA
        soft_red = "#ff9999"
        soft_green = "#99ff99"
        soft_blue = "#9999ff"
        soft_alpha = "#999999"
        colors = [soft_red, soft_green, soft_blue, soft_alpha]
        labels = [r"R", r"G", r"B", r"\alpha"]
        label_colors = [BLACK, BLACK, BLACK, BLACK]

        prisms = []
        label_mobs = []
        order = [0, 1, 2, 3]  # R, G, B, alpha
        for i in order:
            color = colors[i]
            label = labels[i]
            lcolor = label_colors[i]
            prism = Prism(dimensions=[1.75, 6, 6], fill_color=color, fill_opacity=1, stroke_color="#444444", stroke_width=1)
            prism.shift(RIGHT * (i - 2) * 2)
            prisms.append(prism)
            # Center label on front face, offset slightly outward
            front_face_center = prism.get_center() + OUT * (prism.depth / 2)
            label_mob = MathTex(label, color=lcolor, font_size=72).move_to(front_face_center)
            label_mobs.append(label_mob)

        group = VGroup(*list(reversed(prisms)), *list(reversed(label_mobs)))
        group.rotate(PI/6, axis=UP)
        group.shift(UP * 0.5)
        self.add(group)