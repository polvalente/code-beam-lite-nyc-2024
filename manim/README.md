# Manim Source Files

This directory contains all Manim scene files used to generate SVGs and animations for the presentation slides.

## Usage

To render an asset, run:

```
manim -pql <filename.py> <SceneName>
```

For example:

```
manim -pql number_vector_matrix.py NumberVectorMatrix
```

All SVGs and animations should be exported to the `presentation/images/` or `presentation/videos/` directories as appropriate.
