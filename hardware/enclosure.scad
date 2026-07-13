// ============================================================================
// Universal Till — DIY POS enclosure (parametric)
//
// An angled countertop terminal: a hollow wedge BASE that houses the single-
// board computer, and a flat screen BEZEL that closes the slanted top and
// holds the touch panel facing the cashier.
//
// HOW TO USE
//   1. Edit the parameters below for YOUR screen + board.
//   2. Set  part = "base";   press F6, export STL. Print with supports under
//      the rear I/O + cable openings.
//   3. Set  part = "bezel";  press F6, export STL. Prints face (window) down,
//      no supports.
//   4. part = "all";  is a preview of both together — do NOT print that one.
//
// Units: millimetres. As with any printed enclosure, expect a test fit —
// print the bezel and one boss first if you want to check tolerances before
// committing to the full base.
// ============================================================================

part = "all";          // "base" | "bezel" | "all"

// ---- Screen (measure YOUR panel's outer glass/frame) -----------------------
screen_w   = 165;      // panel outline width  (7" HDMI capacitive ~ 165)
screen_h   = 105;      // panel outline height (7" ~ 105)
screen_th  = 6;        // panel thickness (glass + PCB behind)
view_w     = 154;      // active/visible width  (the window cut-out)
view_h     = 86;       // active/visible height

// ---- Board (the compute) ---------------------------------------------------
board      = "pi";     // "pi" = Raspberry Pi 4/5 holes (58 x 49); else generic
board_hx   = 58;       // generic mounting-hole pitch X
board_hy   = 49;       // generic mounting-hole pitch Y
standoff_h = 4;        // standoff height under the board

// ---- Enclosure shell -------------------------------------------------------
wall         = 3;      // wall thickness
base_width   = 120;    // left-right  (keep >= view_w + 2*wall + clearance)
base_depth   = 100;    // front-back footprint
base_height  = 170;    // REAR height  (BIGGER = more upright screen)
front_height = 24;     // FRONT lip height (smaller = screen reclines more)

screw   = 3;           // M3 fastener nominal
boss_d  = 8;           // screw-boss outer diameter
clr     = 0.4;         // general print clearance
$fn = 48;

// ---- Derived ---------------------------------------------------------------
slant_rise = base_height - front_height;
slant_ang  = atan2(slant_rise, base_depth);            // slant from horizontal
face_len   = sqrt(slant_rise*slant_rise + base_depth*base_depth);
hx = (board == "pi") ? 58 : board_hx;
hy = (board == "pi") ? 49 : board_hy;

// slanted side-wall top height at a given depth x
function slant_z(x) = front_height + slant_rise * (x / base_depth);

// ============================================================================
// BASE
// ============================================================================
module wedge_solid() {
    // Side profile in (x = depth, y = height), extruded along the width (Y).
    translate([0, base_width, 0])
        rotate([90, 0, 0])
            linear_extrude(height = base_width)
                polygon([[0, 0],
                         [base_depth, 0],
                         [base_depth, base_height],
                         [0, front_height]]);
}

module vents(count = 6) {
    slot_w = 3; slot_h = 22; gap = 7;
    for (i = [0 : count - 1])
        translate([base_depth * 0.30 + i * gap, -1, 12])
            cube([slot_w, base_width + 2, slot_h]);
}

module board_standoffs() {
    ox = base_depth / 2 - hx / 2;
    oy = base_width / 2 - hy / 2;
    for (px = [0, hx], py = [0, hy])
        translate([ox + px, oy + py, wall])
            difference() {
                cylinder(h = standoff_h, d = boss_d);
                translate([0, 0, -0.1])
                    cylinder(h = standoff_h + 0.2, d = screw - 0.6); // self-tap
            }
}

module wall_bosses() {
    // Four bosses hugging the side walls; bezel flanges screw into heat-set
    // inserts here. Inset overlaps the wall by ~1mm so the boss bonds to it.
    inset = wall + boss_d / 2 - 1;
    for (bx = [base_depth * 0.16, base_depth * 0.84],
         by = [inset, base_width - inset])
        translate([bx, by, slant_z(bx) - 15])
            difference() {
                cylinder(h = 15, d = boss_d);
                translate([0, 0, 15 - 9])
                    cylinder(h = 9.1, d = boss_d - 3.4);  // M3 heat-set pocket
            }
}

module base() {
    difference() {
        wedge_solid();
        // hollow interior (open top; bezel closes it)
        translate([wall, wall, wall])
            cube([base_depth - 2 * wall, base_width - 2 * wall, base_height]);
        // rear I/O opening for board ports
        translate([base_depth - wall - 0.1, base_width / 2 - 30, wall + 2])
            cube([wall + 0.2, 60, 34]);
        // cable slot, rear-bottom
        translate([base_depth - wall - 0.1, base_width / 2 - 12, wall])
            cube([wall + 0.2, 24, 12]);
        vents();
    }
    // solids added AFTER the hollow so they aren't cut away
    board_standoffs();
    wall_bosses();
}

// ============================================================================
// BEZEL  (prints window-side down)
// ============================================================================
module bezel() {
    plate_l = face_len;         // along the slant
    plate_w = base_width;
    th      = wall + 2;         // face-plate thickness
    pocket  = screen_th + clr;  // recess the panel drops into from behind
    inset   = wall + boss_d / 2 - 1;

    difference() {
        cube([plate_l, plate_w, th]);
        // visible window (front lip overlaps the glass edge)
        translate([plate_l / 2 - view_w / 2, plate_w / 2 - view_h / 2, -0.1])
            cube([view_w, view_h, th + 0.2]);
        // panel pocket on the back — holds the glass/frame
        translate([plate_l / 2 - (screen_w + clr) / 2,
                   plate_w / 2 - (screen_h + clr) / 2,
                   th - pocket])
            cube([screen_w + clr, screen_h + clr, pocket + 0.1]);
        // flange screw holes — align with the base wall_bosses
        for (fx = [plate_l * 0.16, plate_l * 0.84],
             fy = [inset, plate_w - inset]) {
            translate([fx, fy, -0.1])
                cylinder(h = th + 0.2, d = screw + clr);   // through hole
            translate([fx, fy, th - 2])
                cylinder(h = 2.2, d = screw + 3);          // countersink
        }
    }
}

// ============================================================================
// PART SELECTOR
// ============================================================================
if (part == "base")       base();
else if (part == "bezel") bezel();
else {
    base();
    // preview only: lay the bezel onto the slant (cosmetic transform)
    color("SteelBlue")
        translate([0, 0, front_height])
            rotate([0, slant_ang, 0])
                bezel();
}
