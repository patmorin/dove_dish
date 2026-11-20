// Parametric Upside-Down Dove Men+Care (106g) Shaving Dish
// 4-arc curved-end barrel profile, compound saddle ribs, and 3D top/bottom edge fillets

$fn = 96;

// --- Parameters (mm) ---
soap_l       = 88.2;  // Inner pocket length (86.5mm bar + 1.7mm clearance)
soap_w       = 63.5;  // Inner pocket max width
end_w        = 33.5;  // Chord width between end corner vertices
end_bulge    = 2.2;   // Outward bow of each short end
fillet_r     = 3.0;   // 2D corner vertex fillet radius
wall         = 3.2;   // Side wall thickness
base_h       = 4.0;   // Base thickness below the cradle
rim_h        = 33.5;  // Wall height above base_h
cradle_depth = 6.5;   // Concave saddle depth

top_fillet   = 1.4;   // 3D fillet radius on top rim (must be <= wall / 2)
bot_fillet   = 1.6;   // 3D fillet radius on bottom outer edge
fillet_steps = 8;     // Smoothness of vertical fillet curves

rib_pitch    = 8.0;   // Center-to-center spacing between ribs
rib_w        = 2.4;   // Rib thickness

// Symmetric rib X positions guaranteed to leave a centered gap at x = 0
rib_xs = [ for (x = [rib_pitch / 2 : rib_pitch : soap_l / 2 - 6]) each [-x, x] ];

// 4-Arc Barrel 2D Profile (curved long sides + subtly bowed short ends)
module dove_barrel_2d(l, w, ew, bulge, fr) {
    vx = (l / 2) - bulge;
    vy = ew / 2;

    // 1. Long side arcs passing through (-vx, vy), (0, w/2), (vx, vy)
    sag_side = (w / 2) - vy;
    r_side   = (pow(vx, 2) + pow(sag_side, 2)) / (2 * sag_side);
    y_off    = r_side - (w / 2);

    // 2. Short end arcs passing through (vx, -vy), (l/2, 0), (vx, vy)
    r_end = (pow(vy, 2) + pow(bulge, 2)) / (2 * bulge);
    x_off = r_end - (l / 2);

    offset(r = fr) offset(delta = -fr)
    intersection() {
        translate([0, -y_off]) circle(r = r_side, $fn = 200);
        translate([0,  y_off]) circle(r = r_side, $fn = 200);
        translate([-x_off, 0]) circle(r = r_end, $fn = 160);
        translate([ x_off, 0]) circle(r = r_end, $fn = 160);
    }
}

total_h = base_h + rim_h;

union() {
    difference() {
        // 1. Solid outer shell with filleted bottom and top outer edges
        union() {
            // Bottom outer fillet (z = 0 to bot_fillet)
            for (i = [0 : fillet_steps - 1]) {
                a0 = 90 * (i / fillet_steps);
                a1 = 90 * ((i + 1) / fillet_steps);
                z0 = bot_fillet * (1 - cos(a0));
                z1 = bot_fillet * (1 - cos(a1));
                d0 = wall - bot_fillet * (1 - sin(a0));
                d1 = wall - bot_fillet * (1 - sin(a1));
                hull() {
                    translate([0, 0, z0])
                        linear_extrude(height = 0.01)
                            offset(delta = d0)
                                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
                    translate([0, 0, z1])
                        linear_extrude(height = 0.01)
                            offset(delta = d1)
                                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
                }
            }

            // Straight outer wall body
            translate([0, 0, bot_fillet])
                linear_extrude(height = total_h - bot_fillet - top_fillet)
                    offset(delta = wall)
                        dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);

            // Top outer fillet (z = total_h - top_fillet to total_h)
            for (i = [0 : fillet_steps - 1]) {
                a0 = 90 * (i / fillet_steps);
                a1 = 90 * ((i + 1) / fillet_steps);
                z0 = (total_h - top_fillet) + top_fillet * sin(a0);
                z1 = (total_h - top_fillet) + top_fillet * sin(a1);
                d0 = wall - top_fillet * (1 - cos(a0));
                d1 = wall - top_fillet * (1 - cos(a1));
                hull() {
                    translate([0, 0, z0])
                        linear_extrude(height = 0.01)
                            offset(delta = d0)
                                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
                    translate([0, 0, z1])
                        linear_extrude(height = 0.01)
                            offset(delta = d1)
                                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
                }
            }
        }

        // 2. Inner pocket subtraction
        translate([0, 0, base_h])
            linear_extrude(height = rim_h + 1)
                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);

        // 3. Top inner lip fillet (flares outward at the top rim so the inner edge is rounded)
        for (i = [0 : fillet_steps - 1]) {
            a0 = 90 * (i / fillet_steps);
            a1 = 90 * ((i + 1) / fillet_steps);
            z0 = (total_h - top_fillet) + top_fillet * sin(a0);
            z1 = (total_h - top_fillet) + top_fillet * sin(a1);
            d0 = top_fillet * (1 - cos(a0));
            d1 = top_fillet * (1 - cos(a1));
            hull() {
                translate([0, 0, z0])
                    linear_extrude(height = 0.01)
                        offset(delta = d0)
                            dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
                translate([0, 0, z1 + (i == fillet_steps - 1 ? 0.5 : 0)])
                    linear_extrude(height = 0.01)
                        offset(delta = d1)
                            dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);
            }
        }
    }

    // 4. Compound-curved (ellipsoidal) saddle ribs
    intersection() {
        translate([0, 0, base_h])
            linear_extrude(height = cradle_depth)
                dove_barrel_2d(soap_l, soap_w, end_w, end_bulge, fillet_r);

        difference() {
            union() {
                for (x = rib_xs)
                    translate([x - rib_w / 2, -soap_w / 2, base_h])
                        cube([rib_w, soap_w, cradle_depth]);
            }
            translate([0, 0, base_h + cradle_depth + 44.8])
                scale([1.0, (soap_w / soap_l) * 1.12, 1.0])
                    sphere(r = 50.0, $fn = 120);
        }
    }
}