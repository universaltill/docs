"""Universal Till — DIY POS enclosure (build123d → STEP for Fusion 360).

The same parametric wedge terminal as enclosure.scad, rebuilt as B-rep
solids and exported to STEP. Fusion 360 (and FreeCAD, SolidWorks, Onshape…)
opens STEP natively as editable solid bodies — edit with Fusion's direct
modeling (press-pull, move face) or use it as the start of your own
timeline. Modern slicers (PrusaSlicer, Bambu, Cura) also slice STEP
directly.

Run (Python 3.10–3.12 with `pip install build123d`):

    python3 enclosure.py    # writes enclosure-base.step + enclosure-bezel.step

Edit the parameters below for YOUR screen + board — same names as the SCAD.
Coordinates: X = depth (front→rear), Y = width, Z = up; floor at Z = 0.
"""

from math import atan2, degrees, sqrt

from build123d import (
    Box,
    BuildPart,
    BuildSketch,
    Cylinder,
    Locations,
    Mode,
    Plane,
    Polygon,
    Pos,
    export_step,
    extrude,
)

# ---- Screen (measure YOUR panel) -------------------------------------------
screen_w, screen_h, screen_th = 165.0, 105.0, 6.0   # panel outline + thickness
view_w, view_h = 154.0, 86.0                        # visible window

# ---- Board ------------------------------------------------------------------
board = "pi"              # "pi" (58 x 49 hole pitch) or "generic"
board_hx, board_hy = 58.0, 49.0
standoff_h = 4.0

# ---- Shell ------------------------------------------------------------------
wall = 3.0
base_width, base_depth = 120.0, 100.0
base_height, front_height = 170.0, 24.0             # rear / front lip heights

screw, boss_d, clr = 3.0, 8.0, 0.4

# ---- Derived ----------------------------------------------------------------
slant_rise = base_height - front_height
slant_ang = degrees(atan2(slant_rise, base_depth))
face_len = sqrt(slant_rise**2 + base_depth**2)
hx, hy = (58.0, 49.0) if board == "pi" else (board_hx, board_hy)


def slant_z(x: float) -> float:
    """Top-of-wall height at depth x (front lip → rear)."""
    return front_height + slant_rise * (x / base_depth)


# ============================================================================
# BASE — hollow wedge, open on the slanted top; the bezel closes it.
# ============================================================================
with BuildPart() as base:
    # solid wedge: side profile on XZ, extruded across the width
    with BuildSketch(Plane.XZ):
        Polygon(
            (0, 0),
            (base_depth, 0),
            (base_depth, base_height),
            (0, front_height),
            align=None,
        )
    extrude(amount=-base_width)

    # hollow the interior (tall box; the slant is already open above)
    with Locations(Pos(base_depth / 2, base_width / 2, wall + base_height / 2)):
        Box(base_depth - 2 * wall, base_width - 2 * wall, base_height,
            mode=Mode.SUBTRACT)

    # rear I/O opening (board ports) and cable slot
    with Locations(Pos(base_depth - wall / 2, base_width / 2, wall + 2 + 17)):
        Box(wall + 0.2, 60, 34, mode=Mode.SUBTRACT)
    with Locations(Pos(base_depth - wall / 2, base_width / 2, wall + 6)):
        Box(wall + 0.2, 24, 12, mode=Mode.SUBTRACT)

    # convection vents through both side walls
    for i in range(6):
        vx = base_depth * 0.30 + i * 7
        with Locations(Pos(vx + 1.5, base_width / 2, 12 + 11)):
            Box(3, base_width + 2, 22, mode=Mode.SUBTRACT)

    # board standoffs on the floor (self-tap pilot holes)
    ox, oy = base_depth / 2 - hx / 2, base_width / 2 - hy / 2
    for px in (0.0, hx):
        for py in (0.0, hy):
            with Locations(Pos(ox + px, oy + py, wall + standoff_h / 2)):
                Cylinder(radius=boss_d / 2, height=standoff_h)
                Cylinder(radius=(screw - 0.6) / 2, height=standoff_h + 0.4,
                         mode=Mode.SUBTRACT)

    # bezel screw bosses hugging the side walls, tops flush with the slant
    inset = wall + boss_d / 2 - 1
    for bx in (base_depth * 0.16, base_depth * 0.84):
        for by in (inset, base_width - inset):
            top = slant_z(bx)
            with Locations(Pos(bx, by, top - 7.5)):
                Cylinder(radius=boss_d / 2, height=15)
            with Locations(Pos(bx, by, top - 4.5)):
                # pocket for an M3 heat-set insert
                Cylinder(radius=(boss_d - 3.4) / 2, height=9.2,
                         mode=Mode.SUBTRACT)

# ============================================================================
# BEZEL — flat plate: window, panel pocket, flange screw holes.
# Prints window-side down; screws onto the base's slanted face.
# ============================================================================
th = wall + 2
pocket = screen_th + clr
inset = wall + boss_d / 2 - 1

with BuildPart() as bezel:
    with Locations(Pos(face_len / 2, base_width / 2, th / 2)):
        Box(face_len, base_width, th)
        # visible window (front lip overlaps the glass edge)
        Box(view_w, view_h, th + 0.2, mode=Mode.SUBTRACT)
    # panel pocket from the back — holds the glass/frame
    with Locations(Pos(face_len / 2, base_width / 2, th - pocket / 2)):
        Box(screen_w + clr, screen_h + clr, pocket + 0.1, mode=Mode.SUBTRACT)
    # flange holes + screw-head pockets, matching the base bosses
    for fx in (face_len * 0.16, face_len * 0.84):
        for fy in (inset, base_width - inset):
            with Locations(Pos(fx, fy, th / 2)):
                Cylinder(radius=(screw + clr) / 2, height=th + 0.2,
                         mode=Mode.SUBTRACT)
            with Locations(Pos(fx, fy, th - 1)):
                Cylinder(radius=(screw + 3) / 2, height=2.2,
                         mode=Mode.SUBTRACT)

export_step(base.part, "enclosure-base.step")
export_step(bezel.part, "enclosure-bezel.step")
print(f"slant angle: {slant_ang:.1f} deg; bezel plate: {face_len:.1f} x {base_width} mm")
print("wrote enclosure-base.step, enclosure-bezel.step")
