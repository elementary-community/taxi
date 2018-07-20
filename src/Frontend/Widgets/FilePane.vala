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

    enum Target {
        STRING,
        URI_LIST;
    }

    const Gtk.TargetEntry[] target_list = {
        { "test/plain",    0, Target.STRING },
        { "text/uri-list", 0, Target.URI_LIST }
    };

    class FilePane : Gtk.Grid {
        private Soup.URI current_uri;
        private PathBar path_bar;
        private Gtk.ListBox list_box;
        private Gtk.Stack stack;

        public signal void file_dragged (string uri);
        public signal void transfer (string uri);
        public signal void navigate (Soup.URI uri);
        public signal void @delete (Soup.URI uri);
        public signal void rename (Soup.URI uri);
        public signal void open (Soup.URI uri);
        public signal void edit (Soup.URI uri);

        delegate void ActivateFunc (Soup.URI uri);

        construct {
            path_bar = new PathBar ();
            path_bar.hexpand = true;
            path_bar.get_style_context ().add_class ("button");

            var placeholder_label = new Gtk.Label (_("This Folder Is Empty"));
            placeholder_label.halign = Gtk.Align.CENTER;
            placeholder_label.valign = Gtk.Align.CENTER;
            placeholder_label.show ();

            var placeholder_label_context = placeholder_label.get_style_context ();
            placeholder_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            placeholder_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            list_box = new Gtk.ListBox ();
            list_box.hexpand = true;
            list_box.vexpand = true;
            list_box.set_placeholder (placeholder_label);
            list_box.set_selection_mode (Gtk.SelectionMode.MULTIPLE);

            var scrolled_pane = new Gtk.ScrolledWindow (null, null);
            scrolled_pane.add (list_box);

            var spinner = new Gtk.Spinner ();
            spinner.hexpand = true;
            spinner.vexpand = true;
            spinner.halign = Gtk.Align.CENTER;
            spinner.valign = Gtk.Align.CENTER;
            spinner.start ();

            stack = new Gtk.Stack ();
            stack.add_named (scrolled_pane, "list");
            stack.add_named (spinner, "spinner");

            var inner_grid = new Gtk.Grid ();
            inner_grid.set_orientation (Gtk.Orientation.VERTICAL);
            inner_grid.add (path_bar);
            inner_grid.add (stack);
            inner_grid.show_all ();

            add (inner_grid);

            list_box.drag_drop.connect (on_drag_drop);
            list_box.drag_data_received.connect (on_drag_data_received);
            list_box.row_activated.connect ((row) => {
                var uri = row.get_data<Soup.URI> ("uri");
                var type = row.get_data<FileType> ("type");
                if (type == FileType.DIRECTORY) {
                    navigate (uri);
                } else {
                    open (uri);
                }
            });

            path_bar.navigate.connect (uri => navigate (uri));
            path_bar.transfer.connect (on_pathbar_transfer);

            Gtk.drag_dest_set (
                list_box,
                Gtk.DestDefaults.ALL,
                target_list,
                Gdk.DragAction.COPY
            );
        }

        private void on_pathbar_transfer () {
            foreach (string uri in get_marked_row_uris ()) {
                transfer (uri);
            }
        }

        private Gee.List<string> get_marked_row_uris () {
            var uri_list = new Gee.ArrayList<string> ();
            foreach (Gtk.Widget row in list_box.get_children ()) {
                if (row.get_data<Gtk.CheckButton> ("checkbutton").get_active ()) {
                    uri_list.add (current_uri.to_string (false) + "/" + row.get_data<string> ("name"));
                }
            }
            return uri_list;
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
            var checkbox = new Gtk.CheckButton ();
            checkbox.toggled.connect (on_checkbutton_toggle);

            var icon = new Gtk.Image.from_gicon (file_info.get_icon (), Gtk.IconSize.DND);

            var name = new Gtk.Label (file_info.get_name ());
            name.halign = Gtk.Align.START;
            name.hexpand = true;

            var row = new Gtk.Grid ();
            row.column_spacing = 6;
            row.hexpand = true;
            row.margin = 6;
            row.add (checkbox);
            row.add (icon);
            row.add (name);

            if (file_info.get_file_type () == FileType.REGULAR) {
                var size = new Gtk.Label (bit_string_format (file_info.get_size ()));
                size.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

                row.add (size);
            }

            var uri = new Soup.URI.with_base (current_uri, file_info.get_name ());

            var ebrow = new Gtk.EventBox ();
            ebrow.add (row);

            var lbrow = new Gtk.ListBoxRow ();
            lbrow.hexpand = true;
            lbrow.add (ebrow);
            lbrow.set_data ("uri", uri);
            lbrow.set_data ("name", file_info.get_name ());
            lbrow.set_data ("type", file_info.get_file_type ());
            lbrow.set_data ("checkbutton", checkbox);

            Gtk.drag_source_set (
                ebrow,
                Gdk.ModifierType.BUTTON1_MASK,
                target_list,
                Gdk.DragAction.COPY
            );

            ebrow.set_data ("name", file_info.get_name ());
            ebrow.set_data ("type", file_info.get_file_type ());
            ebrow.drag_begin.connect (on_drag_begin);
            ebrow.drag_data_get.connect (on_drag_data_get);
            ebrow.button_press_event.connect ((event) =>
                on_ebr_button_press (event, ebrow, lbrow)
            );
            ebrow.popup_menu.connect (() => on_ebr_popup_menu (ebrow));

            return lbrow;
        }

        private void on_checkbutton_toggle () {
            if (get_marked_row_uris ().size > 0) {
                path_bar.transfer_button_sensitive = true;
            } else {
                path_bar.transfer_button_sensitive = false;
            }
        }

        private bool on_ebr_button_press (
            Gdk.EventButton event,
            Gtk.EventBox event_box,
            Gtk.ListBoxRow list_box_row
        ) {
            if (event.button == Gdk.BUTTON_SECONDARY) {
                list_box.select_row (list_box_row);
                event_box.popup_menu ();
            }
            return false;
        }


        private bool on_ebr_popup_menu (Gtk.EventBox event_box) {
            var uri = new Soup.URI.with_base (
                current_uri,
                event_box.get_data<string> ("name")
            );
            var type = event_box.get_data<FileType> ("type");
            var menu = new Gtk.Menu ();
            if (type == FileType.DIRECTORY) {
                menu.add (new_menu_item (_("Open"), u => navigate (u), uri));
            } else {
                menu.add (new_menu_item (_("Open"), u => open (u), uri));
                //menu.add (new_menu_item ("Edit", u => edit (u), uri));
            }
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (new_menu_item (_("Delete"), u => @delete (u), uri));
            //add_menu_item ("Rename", menu, u => rename (u), uri);
            menu.show_all ();
            menu.attach_to_widget (event_box, null);
            menu.popup_at_pointer (null);
            menu.deactivate.connect (() => list_box.select_row (null));
            return true;
        }

        private Gtk.MenuItem new_menu_item (
            string label,
            ActivateFunc activate_fn,
            Soup.URI uri
        ) {
            var menu_item = new Gtk.MenuItem.with_label (label);
            menu_item.activate.connect (() => activate_fn (uri));
            return menu_item;
        }

        public void update_pathbar (Soup.URI uri) {
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

        private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
            var widget_window = widget.get_window ();
            var pixbuf = Gdk.pixbuf_get_from_window (
                widget_window,
                0,
                0,
                widget_window.get_width (),
                widget_window.get_height ()
            );
            Gtk.drag_set_icon_pixbuf (context, pixbuf, 0, 0);
        }

        private bool on_drag_drop (
            Gtk.Widget widget,
            Gdk.DragContext context,
            int x,
            int y,
            uint time
        ) {
            var target_type = (Gdk.Atom) context.list_targets ().nth_data (Target.URI_LIST);
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
            string file_uri = current_uri.to_string (false) + "/" + file_name;
            switch (target_type) {
                case Target.URI_LIST:
                    selection_data.set_uris ({ file_uri });
                    break;
                case Target.STRING:
                    selection_data.set_uris ({ file_uri });
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
                    file_dragged ((string) selection_data.get_data ());
                    break;
                case Target.STRING:
                    break;
                default:
                    message ("Data received not accepted");
                    break;
            }
        }
    }
}
