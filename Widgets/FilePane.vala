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

        public signal void row_clicked (string name);
        public signal void pathbar_activated (string path);

        public FilePane () {
            set_orientation (Gtk.Orientation.VERTICAL);
            build ();
        }

        private void build () {
            add_path_bar ();
            add_list_box ();
        }

        private void add_path_bar () {
            path_bar = new PathBar ();
            add (path_bar);

            path_bar.navigate.connect ((path) => {
                pathbar_activated (path);
            });
        }

        private void add_list_box () {
            list_box = new ListBox ();
            list_box.hexpand = true;
            list_box.vexpand = true;

            var scrolled_pane = new Gtk.ScrolledWindow (null, null);
            scrolled_pane.add (list_box);

            add (scrolled_pane);
        }

        public void update_list (List<FileInfo> file_list) {
            clear_children (list_box);
            foreach (FileInfo file_info in file_list) {
                list_box.add (new_row (file_info));
            }
            list_box.row_activated.connect ((row) => {
                stdout.printf ("test\n");
                row_clicked (row.get_data ("name"));
            });
            list_box.show_all ();
        }

        private Gtk.ListBoxRow new_row (FileInfo file_info) {

            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            row.hexpand = true;
            row.margin = 6;
            //row.get_style_context ().add_class ("error");

            var icon = new Gtk.Image.from_gicon (file_info.get_icon (), Gtk.IconSize.DND);
            icon.set_halign (Gtk.Align.START);
            icon.set_alignment (0f, 0.5f);
            icon.margin_right = 6;
            //icon.get_style_context ().add_class ("warning");
            row.add (icon);

            var name = new Gtk.Label (file_info.get_name ());
            name.hexpand = true;
            name.set_halign (Gtk.Align.START);
            name.set_alignment (0f, 0.5f);
            name.margin_right = 6;
            //name.get_style_context ().add_class ("warning");
            row.add (name);

            var size = new Gtk.Label (file_info.get_size ().to_string ());
            size.set_halign (Gtk.Align.END);
            row.pack_end (size);

            var listboxrow = new Gtk.ListBoxRow ();
            listboxrow.hexpand = true;
            listboxrow.add (row);
            listboxrow.set_data ("name", file_info.get_name ());

            return listboxrow;
        }

        public void update_pathbar (string path) {
            path_bar.setPath (path);
            path_bar.show_all ();
        }

        private void clear_children (Container container) {
            foreach (Widget child in container.get_children ()) {
                container.remove (child);
            }
        }
    }
}
