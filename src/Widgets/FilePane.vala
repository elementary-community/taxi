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
using Gdk;
using Granite;
using Gee;

namespace Taxi {

    enum Target {
        STRING,
        URI_LIST;
    }

    const TargetEntry[] target_list = {
        { "test/plain",    0, Target.STRING },
        { "text/uri-list", 0, Target.URI_LIST }
    };

    class FilePane : Gtk.Grid {

        string current_uri;
        PathBar path_bar;
        Gtk.Label placeholder_label;
        Gtk.ListBox list_box;
        Gtk.Spinner spinner;
        Gtk.ScrolledWindow scrolled_pane;

        public signal void row_clicked (string name);
        public signal void pathbar_activated (string path);
        public signal void file_dragged (string uri);

        public FilePane (bool show_sep = false) {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            build (show_sep);
        }

        private void build (bool show_sep) {
            var inner_grid = new Gtk.Grid ();
            inner_grid.set_orientation (Gtk.Orientation.VERTICAL);
            inner_grid.add (new_path_bar ());
            inner_grid.add (new_list_box ());
            add (inner_grid);

            if (show_sep) {
                var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
                sep.get_style_context ().add_class ("pane-separator");
                add (sep);
            }
        }

        private PathBar new_path_bar () {
            path_bar = new PathBar ();
            path_bar.get_style_context ().add_class ("button");

            path_bar.navigate.connect ((path) => {
                pathbar_activated (path);
            });

            return path_bar;
        }

        private Gtk.ScrolledWindow new_list_box () {
            list_box = new ListBox ();
            list_box.hexpand = true;
            list_box.vexpand = true;

            list_box.row_activated.connect ((row) => {
                row_clicked (row.get_data ("name"));
            });

            placeholder_label = new Gtk.Label ("This folder is empty.");
            placeholder_label.set_halign (Gtk.Align.CENTER);
            placeholder_label.set_valign (Gtk.Align.CENTER);
            placeholder_label.show ();
            list_box.set_placeholder (placeholder_label);

            scrolled_pane = new Gtk.ScrolledWindow (null, null);
            scrolled_pane.add (list_box);

            Gtk.drag_dest_set (
                list_box,
                Gtk.DestDefaults.ALL,
                target_list,
                Gdk.DragAction.COPY
            );

            list_box.drag_drop.connect (on_drag_drop);
            list_box.drag_data_received.connect (on_drag_data_received);

            return scrolled_pane;
        }

        public void update_list (GLib.List<FileInfo> file_list) {
            clear_children (list_box);
            // Have to convert to gee list because glib list sort function is buggy
            // (it randomly removes items...)
            var gee_list = glib_to_gee<FileInfo> (file_list);
            alphabetical_order (gee_list);
            foreach (FileInfo file_info in gee_list) {
                if (file_info.get_name ().get_char (0) == '.') continue;
                list_box.add (new_row (file_info));
            }
            list_box.show_all ();
        }

        private Gee.ArrayList<G> glib_to_gee<G> (GLib.List<G> list) {
            var gee_list = new Gee.ArrayList<G> ();
            foreach (G item in list) {
                gee_list.add (item);
            }
            return gee_list;
        }

        private void alphabetical_order (Gee.ArrayList<FileInfo> file_list) {
            file_list.sort ((a, b) => {
                if ((a.get_file_type () == FileType.DIRECTORY) &&
                    (b.get_file_type () == FileType.DIRECTORY)) {
                    return a.get_name ().collate (b.get_name ());
                }
                if (a.get_file_type () == FileType.DIRECTORY) {
                    return -1;
                }
                if (b.get_file_type () == FileType.DIRECTORY) {
                    return 1;
                }
                return a.get_name ().collate (b.get_name ());
            });
        }

        private Gtk.ListBoxRow new_row (FileInfo file_info) {

            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            row.hexpand = true;
            row.margin = 6;

            var checkbox = new CheckButton ();
            checkbox.margin_end = 6;
            row.add (checkbox);

            row.add (row_icon (file_info));
            row.add (row_name (file_info));

            if (file_info.get_file_type () == FileType.REGULAR) {
                row.pack_end (row_size (file_info));
            }

            var eventboxrow = new Gtk.EventBox ();
            eventboxrow.add (row);

            var listboxrow = new Gtk.ListBoxRow ();
            listboxrow.hexpand = true;
            listboxrow.add (eventboxrow);
            listboxrow.set_data ("name", file_info.get_name ());

            Gtk.drag_source_set (
                eventboxrow,
                Gdk.ModifierType.BUTTON1_MASK,
                target_list,
                Gdk.DragAction.COPY
            );

            eventboxrow.set_data ("name", file_info.get_name ());
            eventboxrow.drag_begin.connect (on_drag_begin);
            eventboxrow.drag_data_get.connect (on_drag_data_get);

            return listboxrow;
        }

        private Gtk.Image row_icon (FileInfo file_info) {
            var icon = new Gtk.Image.from_gicon (file_info.get_icon (), Gtk.IconSize.DND);
            icon.set_halign (Gtk.Align.START);
            icon.set_alignment (0f, 0.5f);
            icon.margin_end = 6;
            return icon;
        }

        private Gtk.Label row_name (FileInfo file_info) {
            var name = new Gtk.Label (file_info.get_name ());
            name.hexpand = true;
            name.set_halign (Gtk.Align.START);
            name.set_alignment (0f, 0.5f);
            name.margin_end = 6;
            return name;
        }

        private Gtk.Label row_size (FileInfo file_info) {
            var size = new Gtk.Label (bit_string_format (file_info.get_size ()));
            size.set_halign (Gtk.Align.END);
            return size;
        }

        public void update_pathbar (string uri) {
            current_uri = uri;
            path_bar.set_path (uri);
            path_bar.show_all ();
        }

        private void clear_children (Gtk.Container container) {
            foreach (Gtk.Widget child in container.get_children ()) {
                container.remove (child);
            }
        }

        public void start_spinner () {
            path_bar.hide ();
            scrolled_pane.hide ();
            spinner = new Gtk.Spinner ();
            spinner.set_hexpand (true);
            spinner.set_vexpand (true);
            spinner.set_halign (Gtk.Align.FILL);
            spinner.start ();
            add (spinner);
            spinner.show ();
        }

        public void stop_spinner () {
            remove (spinner);
            path_bar.show ();
            scrolled_pane.show ();
        }

        private string bit_string_format (int64 bytes) {
            var floatbytes = (float) bytes;
            int i;
            for (i = 0; floatbytes >= 1000.0f || i > 6; i++) {
                floatbytes /= 1000.0f;
            }
            string[] measurement = { "bytes", "kB", "MB", "GB", "TB", "PB", "EB" };
            return "%.3g %s".printf (floatbytes, measurement [i]);
        }

        private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
            debug ("BEGIN WIDGET %s\n", widget.name);
        }

        private bool on_drag_drop (
            Gtk.Widget widget,
            Gdk.DragContext context,
            int x,
            int y,
            uint time
        ) {
            debug ("RECEIVED WIDGET %s\n", widget.name);
            var target_type = (Atom) context.list_targets ().nth_data (Target.URI_LIST);
            Gtk.drag_get_data (widget, context, target_type, time);
            return true;
        }

        private void on_drag_data_get (
            Gtk.Widget widget,
            Gdk.DragContext context,
            Gtk.SelectionData selection_data,
            uint target_type,
            uint time
        ) {
            string file_name = widget.get_data ("name");
            string file_uri = current_uri + "/" + file_name;
            switch (target_type) {
                case Target.URI_LIST:
                    selection_data.set_uris ({ file_uri });
                    debug ("URI TX" + file_uri);
                    break;
                case Target.STRING:
                    selection_data.set_uris ({ file_uri });
                    debug ("STR TX" + file_uri);
                    break;
                default:
                    assert_not_reached ();
            }
        }

        private void on_drag_data_received (
            Gtk.Widget widget,
            Gdk.DragContext context,
            int x,
            int y,
            Gtk.SelectionData selection_data,
            uint target_type,
            uint time
        ) {
            switch (target_type) {
                case Target.URI_LIST:
                    debug ("URI RX " + (string) selection_data.get_data ());
                    file_dragged ((string) selection_data.get_data ());
                    break;
                case Target.STRING:
                    debug ("STR RX" + (string) selection_data.get_data ());
                    break;
                default:
                    message ("Data received not accepted");
                    break;
            }
        }
    }
}
