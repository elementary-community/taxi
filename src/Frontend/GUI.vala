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

    class GUI : Object {

        Gtk.Window window;
        Gtk.HeaderBar header_bar;
        Gtk.EventBox spinner_parent;
        Gtk.Grid outer_box;
        Gtk.Grid pane_inner;
        Gtk.InfoBar infobar;
        Gtk.Spinner spinner;
        Gtk.MenuButton bookmark_menu_button;
        ConnectBox connect_box;
        Granite.Widgets.Welcome welcome;
        FilePane local_pane;
        FilePane remote_pane;
        OperationsPopover popover;
        IConnectionSaver conn_saver;
        IFileAccess remote_access;
        IFileAccess local_access;
        IFileOperations file_operation;
        Soup.URI conn_uri;
        Menu bookmark_menu;
        SavedState saved_state;

        private const string FALLBACK_STYLE = """
            .h1 { font: open sans 24; }
            .h2 { font: open sans light 18; }
            .h3 { font: open sans 12; }
            GraniteWidgetsWelcome {
                background-color: #FFF;
            }
            GraniteWidgetsWelcome GtkLabel {
                color: shade(#333, 2.5);
                font: open sans 11;
                text-shadow: none;
            }

            GraniteWidgetsWelcome .h1,
            GraniteWidgetsWelcome .h3 {
                color: alpha(#333, 0.9);
            }
        """;

        private const string APPLICATION_STYLE = """
            TaxiPathBar GtkButton.path-button {
                background: none;
                border-radius: 0;
                border-width: 0;
                border-image: none;
            }
            TaxiPathBar.button {
                border-width: 0px;
                border-bottom-width: 1px;
                border-image: none;
                border-radius: 0;
            }
        """

#if HAVE_ADWAITA_FIXES
        + """
            .linked .button:insensitive:first-child,
            .linked > GtkComboBox:first-child > .button {
                border-right-width: 0;
                border-left-width: 1px;
                border-image-width: 3px 0 4px 3px;
                border-bottom-right-radius: 0;
                border-top-right-radius: 0;
            }
        """
#endif
        ;

        public GUI (
            IFileAccess local_access,
            IFileAccess remote_access,
            IFileOperations file_operation,
            IConnectionSaver conn_saver
        ) {
            this.local_access = local_access;
            this.remote_access = remote_access;
            this.file_operation = file_operation;
            this.conn_saver = conn_saver;
        }

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_outerbox ();
            add_welcome ();
            setup_window ();
            setup_styles ();
            setup_spinner ();
            setup_other_connects ();
            add_popover ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar = new Gtk.HeaderBar ();
            connect_box = new ConnectBox ();
            header_bar.set_show_close_button (true);
            header_bar.set_custom_title (new Gtk.Label (null));
            header_bar.pack_start (new_bookmark_list_button ());
            header_bar.pack_start (connect_box);
            connect_box.connect_initiated.connect (this.on_connect_initiated);
            connect_box.ask_hostname.connect (this.on_ask_hostname);
            connect_box.bookmarked.connect (this.bookmark);
        }

        private Gtk.MenuButton new_bookmark_list_button () {
            bookmark_menu_button = new Gtk.MenuButton ();
            var button_image = new Gtk.Image.from_icon_name (
                "user-bookmarks-symbolic",
                Gtk.IconSize.BUTTON
            );
            bookmark_menu_button.add (button_image);
            bookmark_menu = new Menu ();
            bookmark_menu_button.set_menu_model (bookmark_menu);
            bookmark_menu_button.set_use_popover (true);
            update_bookmark_menu ();
            return bookmark_menu_button;
        }

        private void add_outerbox () {
            outer_box = new Gtk.Grid ();
            outer_box.set_orientation (Gtk.Orientation.VERTICAL);
            outer_box.set_column_homogeneous (true);
            window.add (outer_box);
        }

        private void add_welcome () {
            welcome = new Granite.Widgets.Welcome (
                _("Connect"),
                _("Type a URL and press 'Enter' to\nconnect to a server.")
            );
            welcome.vexpand = true;
            outer_box.add (welcome);
            window.key_press_event.connect (connect_box.on_key_press_event);
        }

        private void remove_welcome () {
            outer_box.remove (welcome);
            window.key_press_event.disconnect (connect_box.on_key_press_event);
        }

        private void on_connect_initiated (Soup.URI uri) {
            show_spinner ();
            remote_access.connect_to_device.begin (uri, window, (obj, res) => {
                if (remote_access.connect_to_device.end (res)) {
                    if (local_pane == null) {
                        remove_welcome ();
                        add_panes ();
                        window.show_all ();
                    }
                    update_pane (Location.LOCAL);
                    update_pane (Location.REMOTE);
                    connect_box.show_favorite_icon (
                        conn_saver.is_bookmarked (remote_access.get_uri ())
                    );
                    conn_uri = uri;
                } else {
                    welcome.title = _("Could not connect to '%s'").printf (
                        uri.to_string (false)
                    );
                }
                hide_spinner ();
            });
        }

        private void show_spinner () {
            spinner_parent.show_all ();
            header_bar.pack_end (spinner_parent);
        }

        private void hide_spinner () {
            header_bar.remove (spinner_parent);
        }

        private void bookmark () {
            var uri_string = conn_uri.to_string (false);
            if (conn_saver.is_bookmarked (uri_string)) {
                conn_saver.remove (uri_string);
            } else {
                conn_saver.save (uri_string);
            }
            connect_box.show_favorite_icon (
                conn_saver.is_bookmarked (uri_string)
            );
            update_bookmark_menu ();
        }

        private void update_bookmark_menu () {
            bookmark_menu.remove_all ();
            var uri_list = conn_saver.get_saved_conns ();
            if (uri_list.length () == 0) {
                bookmark_menu_button.set_sensitive (false);
            } else {
                foreach (string uri in uri_list) {
                    bookmark_menu.append (uri, null);
                }
                bookmark_menu_button.set_sensitive (true);
            }
        }

        private void add_panes () {
            pane_inner = new Gtk.Grid ();
            pane_inner.set_column_homogeneous (true);

            local_pane = new FilePane (true);
            pane_inner.add (local_pane);

            local_pane.row_clicked.connect (this.on_local_row_clicked);
            local_pane.pathbar_activated.connect (this.on_local_pathbar_activated);
            local_pane.file_dragged.connect (this.on_local_file_dragged);
            local_pane.transfer.connect (this.on_remote_file_dragged);
            local_pane.@delete.connect (uri => on_file_delete (uri, Location.LOCAL));
            local_access.directory_changed.connect (() => update_pane (Location.LOCAL));

            remote_pane = new FilePane ();
            pane_inner.add (remote_pane);
            remote_pane.row_clicked.connect (this.on_remote_row_clicked);
            remote_pane.pathbar_activated.connect (this.on_remote_pathbar_activated);
            remote_pane.file_dragged.connect (this.on_remote_file_dragged);
            remote_pane.transfer.connect (this.on_local_file_dragged);
            remote_pane.@delete.connect (uri => on_file_delete (uri, Location.REMOTE));

            outer_box.add (pane_inner);
        }

        private void on_local_pathbar_activated (string path) {
            local_access.goto_path (path);
            update_pane (Location.LOCAL);
        }

        private void on_local_row_clicked (string name) {
            local_access.goto_child (name);
            update_pane (Location.LOCAL);
        }

        private void on_remote_pathbar_activated (string path) {
            remote_access.goto_path (path);
            update_pane (Location.REMOTE);
        }

        private void on_remote_row_clicked (string name) {
            remote_access.goto_child (name);
            update_pane (Location.REMOTE);
        }

        private void on_remote_file_dragged (string uri) {
            on_file_dragged (uri, Location.REMOTE, remote_access);
        }

        private void on_local_file_dragged (string uri) {
            on_file_dragged (uri, Location.LOCAL, local_access);
        }

        private void on_file_dragged (
            string uri,
            Location pane,
            IFileAccess file_access
        ) {
            var source_file = File.new_for_uri (uri.replace ("\r\n", ""));
            var dest_file = file_access.get_current_file ().get_child (source_file.get_basename ());
            file_operation.copy_recursive.begin (
                source_file,
                dest_file,
                FileCopyFlags.NONE,
                new Cancellable (),
                (obj, res) => {
                    try {
                        file_operation.copy_recursive.end (res);
                        update_pane (pane);
                    } catch (Error e) {
                        new_infobar (e.message, Gtk.MessageType.ERROR);
                    }
                }
             );
        }

        private void on_file_delete (Soup.URI uri, Location pane) {
            var file = File.new_for_uri (uri.to_string (false));
            file_operation.delete_recursive.begin (
                file,
                new Cancellable (),
                (obj, res) => {
                    try {
                        file_operation.delete_recursive.end (res);
                        update_pane (pane);
                    } catch (Error e) {
                        debug (e.message);
                        new_infobar (e.message, Gtk.MessageType.ERROR);
                    }
                }
            );
        }

        private void new_infobar (string message, Gtk.MessageType message_type) {
            remove_existing_infobar ();
            infobar = new Gtk.InfoBar ();
            var content = infobar.get_content_area ();
            content.add (new Gtk.Label (message));
            infobar.set_message_type (message_type);
            infobar.set_show_close_button (true);
            outer_box.attach_next_to (infobar, pane_inner, Gtk.PositionType.TOP, 1, 1);
            outer_box.show_all ();
            infobar.response.connect (() => outer_box.remove (infobar));
        }

        private void remove_existing_infobar () {
            foreach (Gtk.Widget outer_box_child in outer_box.get_children ()) {
                if (outer_box_child == infobar) {
                    outer_box.remove (infobar);
                }
            }
        }

        private void update_pane (Location pane) {
            IFileAccess file_access;
            FilePane file_pane;
            switch (pane) {
                case Location.REMOTE:
                    file_access = remote_access;
                    file_pane = remote_pane;
                    break;
                case Location.LOCAL:
                default:
                    file_access = local_access;
                    file_pane = local_pane;
                    break;
            }
            file_pane.start_spinner ();
            var file_uri = file_access.get_uri ();
            file_access.get_file_list.begin ((obj, res) => {
            var file_files = file_access.get_file_list.end (res);
                file_pane.stop_spinner ();
                file_pane.update_list (file_files);
                file_pane.update_pathbar (file_uri);
            });
        }

        private Soup.URI on_ask_hostname () {
            return conn_uri;
        }

        private void add_popover () {
            popover = new OperationsPopover (spinner);
            popover.operations_pending.connect (this.show_spinner);
            popover.operations_finished.connect (this.hide_spinner);
            file_operation.operation_added.connect (popover.add_operation);
            file_operation.operation_removed.connect (popover.remove_operation);
            spinner_parent.button_press_event.connect (() => {
                popover.show_all ();
                return false;
            });
        }

        private void setup_spinner () {
            spinner = new Gtk.Spinner ();
            spinner.start ();
            spinner.margin_end = 6;
            spinner_parent = new Gtk.EventBox ();
            spinner_parent.add (spinner);
        }

        private void setup_styles () {
            Granite.Widgets.Utils.set_theming_for_screen (
                Gdk.Screen.get_default (),
                FALLBACK_STYLE,
                Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK
            );
            Granite.Widgets.Utils.set_theming_for_screen (
                Gdk.Screen.get_default (),
                APPLICATION_STYLE,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        private void setup_other_connects () {
            file_operation.ask_overwrite.connect (on_ask_overwrite);
        }

        private int on_ask_overwrite (File destination) {
            var dialog = new Gtk.MessageDialog (
                window,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.NONE,
                _("Replace existing file?")
            );
            dialog.format_secondary_markup (
                _("<i>\"%s\"</i> already exists. You can replace this file, replace all conflicting files or choose not to replace the file by skipping.".printf (destination.get_basename ()))
            );
            dialog.add_button (_("Replace All Conflicts"), 2);
            dialog.add_button (_("Skip"), 0);
            dialog.add_button (_("Replace"), 1);
            dialog.get_widget_for_response (1).get_style_context ().add_class ("suggested-action");

            var response = dialog.run ();
            dialog.destroy ();
            return response;
        }

        private void setup_window () {
            saved_state = new SavedState ();
            window.default_width = saved_state.window_width;
            window.default_height = saved_state.window_height;
            window.move (saved_state.opening_x, saved_state.opening_y);
            if (saved_state.maximized) {
                window.maximize ();
            }
            window.set_titlebar (header_bar);
            window.show_all ();

            window.delete_event.connect (this.on_delete_window);
            window.destroy.connect (Gtk.main_quit);
        }

        private bool on_delete_window () {
            if ((window.get_window ().get_state () & Gdk.WindowState.MAXIMIZED) == 0) {
                int window_width, window_height;
                window.get_size (out window_width, out window_height);
                saved_state.window_width = window_width;
                saved_state.window_height = window_height;
                saved_state.maximized = false;
            } else {
                saved_state.maximized = true;
            }

            int x_pos, y_pos;
            window.get_position (out x_pos, out y_pos);
            saved_state.opening_x = x_pos;
            saved_state.opening_y = y_pos;

            return false;
        }
    }
}
