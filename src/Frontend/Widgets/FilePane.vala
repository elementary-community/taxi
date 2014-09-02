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

        Soup.URI current_uri;
        PathBar path_bar;
        Gtk.Label placeholder_label;
        Gtk.ListBox list_box;
        Gtk.Spinner? spinner;
        Gtk.ScrolledWindow scrolled_pane;
        Gtk.Grid inner_grid;

        public signal void file_dragged (string uri);
        public signal void transfer (string uri);
        public signal void navigate (Soup.URI uri);
        public signal void @delete (Soup.URI uri);
        public signal void rename (Soup.URI uri);
        public signal void open (Soup.URI uri);
        public signal void edit (Soup.URI uri);

        delegate void ActivateFunc (Soup.URI uri);

        public FilePane (bool show_sep = false) {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            build (show_sep);
        }

        private void build (bool show_sep) {
            inner_grid = new Gtk.Grid ();
            inner_grid.set_orientation (Gtk.Orientation.VERTICAL);
            inner_grid.add (new_path_bar ());
            inner_grid.add (new_list_box ());
            add (inner_grid);
            inner_grid.show_all ();

            if (show_sep) {
                var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
                sep.get_style_context ().add_class ("pane-separator");
                add (sep);
            }
        }

        private PathBar new_path_bar () {
            path_bar = new PathBar ();
            path_bar.hexpand = true;
            path_bar.set_halign (Gtk.Align.FILL);
            path_bar.get_style_context ().add_class ("button");
            path_bar.navigate.connect (uri => navigate (uri));
            path_bar.transfer.connect (on_pathbar_transfer);
            return path_bar;
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

        private Gtk.ScrolledWindow new_list_box () {
            list_box = new Gtk.ListBox ();
            list_box.hexpand = true;
            list_box.vexpand = true;
            list_box.set_selection_mode (Gtk.SelectionMode.MULTIPLE);

            list_box.row_activated.connect ((row) => {
                var uri = row.get_data<Soup.URI> ("uri");
                var type = row.get_data<FileType> ("type");
                if (type == FileType.DIRECTORY) {
                    navigate (uri);
                } else {
                    open (uri);
                }
            });

            placeholder_label = new Gtk.Label (_("This folder is empty."));
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

            var checkbox = new Gtk.CheckButton ();
            checkbox.margin_end = 6;
            row.add (checkbox);

            row.add (row_icon (file_info));
            row.add (row_name (file_info));

            if (file_info.get_file_type () == FileType.REGULAR) {
                row.pack_end (row_size (file_info));
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
            menu.popup (null, null, null, 0, Gtk.get_current_event_time ());
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
            scrolled_pane.hide ();
            if (spinner == null) {
                spinner = new Gtk.Spinner ();
                spinner.set_hexpand (true);
                spinner.set_vexpand (true);
                spinner.set_halign (Gtk.Align.FILL);
                spinner.start ();
                inner_grid.add (spinner);
            }
            spinner.show ();
        }

        public void stop_spinner () {
            if (spinner != null) {
                inner_grid.remove (spinner);
                spinner = null;
            }
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
