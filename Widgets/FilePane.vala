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

using Gtk;
using Granite;

namespace Shift {

    class FilePane : Gtk.Grid {

        PathBar path_bar;
        ListBox list_box;

        public FilePane () {
            set_orientation (Gtk.Orientation.VERTICAL);
            build ();
        }

        private void build () {
            add_path_bar ();
            add_list_box ();
        }

        private void add_path_bar () {
            path_bar = new PathBar.from_path ("/home/khampal/test/");
            add (path_bar);
        }

        private void add_list_box () {
            list_box = new ListBox ();
            list_box.hexpand = true;
            list_box.vexpand = true;

            var scrolled_pane = new Gtk.ScrolledWindow (null, null);
            scrolled_pane.add (list_box);

            add (scrolled_pane);
        }
    }
}
