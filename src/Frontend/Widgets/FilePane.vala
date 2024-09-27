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

    class FilePane : Adw.Bin {
        private GLib.Uri current_uri;
        private PathBar path_bar;
        private Gtk.ListBox list_box;
        private Gtk.Stack stack;
        private Gtk.Popover menu_popover;

        public signal void file_dragged (string uri);
        public signal void transfer (string uri);
        public signal void navigate (GLib.Uri uri);
        public signal void rename (GLib.Uri uri);
        public signal void open (GLib.Uri uri);
        public signal void edit (GLib.Uri uri);

        delegate void ActivateFunc (GLib.Uri uri);

        construct {
            path_bar = new PathBar () {
                hexpand = true
            };

            var placeholder_label = new Gtk.Label (_("This Folder Is Empty")) {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            placeholder_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
            placeholder_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            list_box = new Gtk.ListBox () {
                hexpand = true,
                vexpand = true
            };

            list_box.set_placeholder (placeholder_label);
            list_box.set_selection_mode (Gtk.SelectionMode.MULTIPLE);
            list_box.add_css_class ("transition");
            list_box.add_css_class ("drop-target");

            var listbox_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            listbox_view.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            listbox_view.append (list_box);

            var scrolled_pane = new Gtk.ScrolledWindow () {
                child = listbox_view
            };

            var spinner = new Gtk.Spinner () {
                hexpand = true,
                vexpand = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            spinner.start ();

            stack = new Gtk.Stack ();
            stack.add_named (scrolled_pane, "list");
            stack.add_named (spinner, "spinner");

            var toolbar = new Adw.ToolbarView ();
            toolbar.add_top_bar (path_bar);
            toolbar.content = stack;

            child = toolbar;

            list_box.row_activated.connect ((row) => {
                var uri = row.get_data<GLib.Uri> ("uri");
                var type = row.get_data<FileType> ("type");
                if (type == FileType.DIRECTORY) {
                    navigate (uri);
                } else {
                    open (uri);
                }
            });

            path_bar.navigate.connect (uri => navigate (uri));
            path_bar.transfer.connect (on_pathbar_transfer);

            var drop_target = new Gtk.DropTarget (typeof (Gtk.ListBoxRow), Gdk.DragAction.COPY);
		    list_box.add_controller (drop_target);
            drop_target.drop.connect ((value, x, y) => {
                var row = (Gtk.ListBoxRow) value;
                var uri = row.get_data<GLib.Uri> ("uri");

                if (uri != null) {
                    file_dragged (uri.to_string ());
                }

                return true;
            });
        }

        private void on_pathbar_transfer () {
            foreach (string uri in get_marked_row_uris ()) {
                transfer (uri);
            }
        }

        private Gee.List<string> get_marked_row_uris () {
            var uri_list = new Gee.ArrayList<string> ();

            Gtk.ListBoxRow row = null;
            var row_index = 0;

            do {
                row = list_box.get_row_at_index (row_index);
                if (row.get_data<Gtk.CheckButton> ("checkbutton").get_active ()) {
                    uri_list.add (current_uri.to_string () + "/" + row.get_data<string> ("name"));
                }

                row_index++;
            } while (row != null);

            return uri_list;
        }

        public void update_list (GLib.List<FileInfo> file_list) {
            clear_children (list_box);
            // Have to convert to gee list because glib list sort function is buggy
            // (it randomly removes items...)
            var gee_list = glib_to_gee<FileInfo> (file_list);
            alphabetical_order (gee_list);
            foreach (FileInfo file_info in gee_list) {
                if (file_info.get_name ().get_char (0) == '.') {
                    continue;
                }

                var row = new_row (file_info);
                if (row != null) {
                    list_box.append (row);
                }
            }
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

        private Gtk.ListBoxRow? new_row (FileInfo file_info) {
            var checkbox = new Gtk.CheckButton ();
            checkbox.toggled.connect (on_checkbutton_toggle);

            var icon = new Gtk.Image.from_gicon (file_info.get_icon ());

            var name = new Gtk.Label (file_info.get_name ());
            name.halign = Gtk.Align.START;
            name.hexpand = true;

            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                hexpand = true,
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 12,
                margin_end = 12
            };
            row.append (checkbox);
            row.append (icon);
            row.append (name);

            if (file_info.get_file_type () == FileType.REGULAR) {
                var size = new Gtk.Label (bit_string_format (file_info.get_size ()));
                size.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
                row.append (size);
            }

            GLib.Uri uri;
            try {
                uri = GLib.Uri.parse_relative (current_uri, file_info.get_name (), PARSE_RELAXED);
            } catch (Error e) {
                message (e.message);
                return null;
            }

            var ebrow = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            ebrow.append (row);
            ebrow.set_data ("name", file_info.get_name ());
            ebrow.set_data ("type", file_info.get_file_type ());

            var lbrow = new Gtk.ListBoxRow () {
                hexpand = true,
                child = ebrow
            };
            lbrow.set_data ("uri", uri);
            lbrow.set_data ("name", file_info.get_name ());
            lbrow.set_data ("type", file_info.get_file_type ());
            lbrow.set_data ("checkbutton", checkbox);

            var drag_source = new Gtk.DragSource ();
            drag_source.set_actions (Gdk.DragAction.COPY);
            lbrow.add_controller (drag_source);

            drag_source.prepare.connect ((x, y) => {
                return new Gdk.ContentProvider.for_value (lbrow);
            });

            drag_source.drag_begin.connect ((source, drag) => {
                var paintable = new Gtk.WidgetPaintable (lbrow);
                source.set_icon (paintable, 0, 0);
            });

            return lbrow;
        }

        private void on_checkbutton_toggle () {
            if (get_marked_row_uris ().size > 0) {
                path_bar.transfer_button_sensitive = true;
            } else {
                path_bar.transfer_button_sensitive = false;
            }
        }

        public void update_pathbar (GLib.Uri uri) {
            current_uri = uri;
            path_bar.set_path (uri);
        }

        private void clear_children (Gtk.ListBox listbox) {
            listbox.remove_all ();
        }

        public void start_spinner () {
            stack.visible_child_name = "spinner";
        }

        public void stop_spinner () {
            stack.visible_child_name = "list";
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
    }
}
