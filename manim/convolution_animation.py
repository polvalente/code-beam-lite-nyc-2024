from manim import *
import numpy as np

class ConvolutionAnimation(Scene):
    def construct(self):
        self.camera.background_color = WHITE
        # 4x4 matrix
        matrix = np.arange(1, 17).reshape(4, 4) % 7
        # Adjust h_buff/v_buff for wider cells
        table_config = dict(include_outer_lines=True, element_to_mobject_config={"color": BLACK, "font_size": 48}, h_buff=2, v_buff=1.1)
        mobj = IntegerTable(matrix, **table_config)
        mobj.set_color(BLACK)
        mobj.set_stroke(BLACK)
        mobj.to_edge(LEFT)

        # 2x2 kernel (your requested values)
        kernel = np.array([[1, 1], [0, 1]])
        kobj = IntegerTable(kernel, **table_config)
        kobj.set_fill(WHITE, opacity=0.0)
        kobj.set_stroke(color=DARK_BLUE, width=4)
        kobj.set_color(DARK_BLUE)

        # Result matrix (3x3)
        result_matrix = np.ones((3, 3), dtype=int) * 10
        result_obj = IntegerTable(result_matrix, **table_config)
        result_obj.set_color(WHITE)
        result_obj.set_stroke(BLACK)
        result_obj.next_to(mobj, RIGHT, buff=2)
        result_label = Text("Result", font_size=40, color=BLACK).next_to(result_obj, UP)
        self.add(mobj, kobj, result_obj, result_label)

        group = VGroup(mobj, result_obj, kobj)

        width_scale = group.get_width() / self.camera.frame_width * 1.2
        height_scale = group.get_height() / self.camera.frame_height * 1.2

        print(width_scale, height_scale)

        scale = max(width_scale, height_scale)

        self.camera.frame_width *= scale
        self.camera.frame_height *= scale
        self.camera.frame_center = group.get_center()

        # Helper: get top-left cell center of a table
        def top_left_cell_center(table):
            return table.get_cell((1, 1)).get_center()

        # Animation: slide kernel over matrix with 0-padding
        positions = [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1), (1, 2),
            (2, 0), (2, 1), (2, 2)
        ]
        # Move kernel so its top-left cell overlays the matrix's (1,1)
        kobj.next_to(mobj, UP, buff=2)
        kobj.animate.move_to(top_left_cell_center(mobj))
        self.wait(0.5)
        # Prepare result cell references, but do not add any initial text
        result_cell_mobs = {}
        for i in range(3):
            for j in range(3):
                cell = result_obj.get_cell((i+1, j+1))
                # Remove any default text (including zeros)
                for submob in list(cell.submobjects):
                    if isinstance(submob, Text):
                        cell.remove(submob)
                result_cell_mobs[(i, j)] = cell
        for idx, (i, j) in enumerate(positions):
            # Compute where the top-left of the kernel should go
            target = mobj.get_cell((i+1, j+1)).get_center()
            shift_vec = target - top_left_cell_center(kobj)
            self.play(kobj.animate.shift(shift_vec), run_time=1.0)
            # Extract 2x2 region with 0-padding
            region = np.zeros((2,2), dtype=int)
            for ki in range(2):
                for kj in range(2):
                    mi, mj = i+ki, j+kj
                    if 0 <= mi < 4 and 0 <= mj < 4:
                        region[ki, kj] = matrix[mi, mj]
            result = int(np.sum(region * kernel))
            # Show result value
            result_mob = Text(str(result), color=BLACK, font_size=56)
            result_mob.move_to(kobj.get_center())
            self.add(result_mob)
            # Animate result flying to result matrix
            dest = result_obj.get_cell((i+1, j+1)).get_center()
            self.play(result_mob.animate.move_to(dest), run_time=0.8)
            # Place the result number in the cell (cell starts empty)
            cell = result_cell_mobs[(i, j)]
            cell.submobjects.clear()
            cell.add(result_mob)
            self.wait(0.2)