/***
  Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see <http://www.gnu.org/licenses>
***/

namespace Taxi {

    class PathBarSeparator : Gtk.Widget {

        construct {
            set_has_window (false);
        }

        public override bool draw (Cairo.Context cr) {
            int width = get_allocated_width ();
            int height = get_allocated_height ();

            cr.set_antialias (Cairo.Antialias.SUBPIXEL);
            cr.set_line_cap (Cairo.LineCap.SQUARE);

            cr.set_source_rgba (1d, 1d, 1d, 0.8);
            cr.set_line_width (2);
            cr.move_to (0, 2);
            cr.line_to (width, height / 2 + 1);
            cr.line_to (0, height);
            cr.stroke ();

            cr.set_source_rgba (0.7d, 0.7d, 0.7d, 0.8);
            cr.set_line_width (1);
            cr.move_to (0, 0);
            cr.line_to (width - 1, height / 2);
            cr.line_to (0, height - 1);
            cr.stroke ();

            return true;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            minimum_width = 10;
            natural_width = 10;
        }
    }
}
