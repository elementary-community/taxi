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
        Gtk.Grid outer_box;
        Gtk.Grid pane_inner;
        Gtk.Spinner spinner;
        ConnectBox connect_box;
        Granite.Widgets.Welcome welcome;
        FilePane local_pane;
        FilePane remote_pane;
        IConnectionSaver conn_saver;
        IFileAccess remote_access;
        IFileAccess local_access;
        IFileOperations file_operation;

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
            GtkButton.path-button {
                background: none;
                border-radius: 0;
                border-width: 0;
                border-image: none;
            }
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
            }
            GtkHeaderBar GtkComboBox {
                padding-left: 6px;
            }
        """;

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
            this.remote_access.connected.connect (() => {
            });
        }

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_outerbox ();
            add_welcome ();
            setup_window ();
            setup_styles ();
            setup_spinner ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar = new Gtk.HeaderBar ();
            connect_box = new ConnectBox ();
            header_bar.set_show_close_button (true);
            header_bar.set_custom_title (new Gtk.Label (null));
            header_bar.pack_start (connect_box);
            connect_box.connect_initiated.connect (this.connect_init);
            connect_box.bookmarked.connect (this.bookmark);
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
                _("Type an URL and press 'Enter' to\nconnect to a server.")
            );
            welcome.vexpand = true;
            outer_box.add (welcome);
        }

        private void connect_init (IConnInfo conn) {
            show_spinner ();
            remote_access.connect_to_device.begin (conn, window, (obj, res) => {
                if (remote_access.connect_to_device.end (res)) {
                    if (local_pane == null) {
                        outer_box.remove (welcome);
                        add_panes ();
                    }
                    update_local_pane ();
                    update_remote_pane ();
                    connect_box.show_favorite_icon (
                        conn_saver.is_bookmarked (remote_access.get_uri ())
                    );
                    window.show_all ();
                } else {
                    welcome.title = _("Could not connect to '%s:%s'").printf (
                        conn.hostname,
                        conn.port.to_string ()
                    );
                }
                hide_spinner ();
            });
        }

        private void show_spinner () {
            spinner.show ();
            header_bar.add (spinner);
        }

        private void hide_spinner () {
            header_bar.remove (spinner);
        }

        private void bookmark () {
            if (conn_saver.is_bookmarked (remote_access.get_uri ())) {
                conn_saver.remove (remote_access.get_uri ());
            } else {
                conn_saver.save (remote_access.get_uri ());
            }
            connect_box.show_favorite_icon (
                conn_saver.is_bookmarked (remote_access.get_uri ())
            );
        }

        private void add_panes () {
            pane_inner = new Gtk.Grid ();
            pane_inner.set_column_homogeneous (true);

            local_pane = new FilePane (true);
            pane_inner.add (local_pane);

            local_pane.row_clicked.connect (this.on_local_row_clicked);
            local_pane.pathbar_activated.connect (this.on_local_pathbar_activated);
            local_pane.file_dragged.connect (this.on_local_file_dragged);
            local_access.directory_changed.connect (this.update_local_pane);

            remote_pane = new FilePane ();
            pane_inner.add (remote_pane);
            remote_pane.row_clicked.connect (this.on_remote_row_clicked);
            remote_pane.pathbar_activated.connect (this.on_remote_pathbar_activated);
            remote_pane.file_dragged.connect (this.on_remote_file_dragged);

            outer_box.add (pane_inner);
        }

        private void on_local_pathbar_activated (string path) {
            local_access.goto_path (path);
            update_local_pane ();
        }

        private void on_local_row_clicked (string name) {
            local_access.goto_child (name);
            update_local_pane ();
        }

        private void on_remote_pathbar_activated (string path) {
            remote_access.goto_path (path);
            update_remote_pane ();
        }

        private void on_remote_row_clicked (string name) {
            remote_access.goto_child (name);
            update_remote_pane ();
        }

        private void on_remote_file_dragged (string uri) {
            on_file_dragged (uri, remote_pane, remote_access);
        }

        private void on_local_file_dragged (string uri) {
            on_file_dragged (uri, local_pane, local_access);
        }

        private void on_file_dragged (string uri, FilePane file_pane, IFileAccess file_access) {
            var source_file = File.new_for_uri (uri.replace ("\r\n", ""));
            var dest_file = file_access.get_current_file ().get_child (source_file.get_basename ());
            file_operation.copy_recursive.begin (
                source_file,
                dest_file,
                FileCopyFlags.NONE,
                null,
                (obj, res) => {
                    try {
                        file_operation.copy_recursive.end (res);
                        update_pane (file_access, file_pane);
                        debug ("Recursive file copy finished!");
                    } catch (Error e) {
                        new_infobar (e.message, Gtk.MessageType.ERROR);
                    }
                }
             );
        }

        private void new_infobar (string message, Gtk.MessageType message_type) {
            var infobar = new Gtk.InfoBar ();
            var content = infobar.get_content_area ();
            content.add (new Gtk.Label (message));
            infobar.set_message_type (message_type);
            infobar.set_show_close_button (true);
            outer_box.attach_next_to (infobar, pane_inner, Gtk.PositionType.TOP, 1, 1);
            outer_box.show_all ();
            infobar.response.connect (() => outer_box.remove (infobar));
        }

        private void update_local_pane () {
            update_pane (local_access, local_pane);
        }

        private void update_remote_pane () {
            update_pane (remote_access, remote_pane);
        }

        private void update_pane (IFileAccess file_access, FilePane file_pane) {
            var file_uri = file_access.get_uri ();
            file_access.get_file_list.begin ((obj, res) => {
                var file_files = file_access.get_file_list.end (res);
                file_pane.update_list (file_files);
                file_pane.update_pathbar (file_uri);
            });
        }

        private void setup_spinner () {
            spinner = new Gtk.Spinner ();
            spinner.margin_start = 6;
            spinner.start ();
        }

        private void setup_styles () {
            try {
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
            } catch (FileError e) {
                warning (e.message);
            }
        }

        private void setup_window () {
            window.default_width = 650;
            window.default_height = 550;
            window.set_titlebar (header_bar);
            window.show_all ();

            window.destroy.connect (Gtk.main_quit);
        }
    }
}
