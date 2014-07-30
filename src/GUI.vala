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

namespace Taxi {

    class GUI : Object {

        Gtk.Window window;
        Gtk.HeaderBar header_bar;
        ConnectBox connect_box;
        Granite.Widgets.Welcome welcome;
        FilePane local_pane;
        FilePane remote_pane;
        IConnectionSaver conn_saver;
        IFileAccess remote_access;
        IFileAccess local_access;

        public GUI (
            IFileAccess local_access,
            IFileAccess remote_access,
            IFileOperations file_operation,
            IConnectionSaver conn_saver
        ) {
            this.local_access = local_access;
            this.remote_access = remote_access;
            this.conn_saver = conn_saver;

            this.remote_access.connected.connect (() => {
            });
        }

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_welcome ();
            setup_window ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar = new HeaderBar ();
            connect_box = new ConnectBox ();
            header_bar.set_show_close_button (true);
            header_bar.set_custom_title (new Gtk.Label (null));
            header_bar.pack_start (connect_box);

            connect_box.connect_initiated.connect (this.connect_init);
            connect_box.bookmarked.connect (this.bookmark);
        }

        private void add_welcome () {
            welcome = new Granite.Widgets.Welcome (
                "Connect",
                "Type an URL and press 'Enter' to connect to a server."
            );
            welcome.margin = 12;
            window.add (welcome);
        }

        private void connect_init (IConnInfo conn) {
            remote_access.connect_to_device.begin (conn, (obj, res) => {
                if (remote_access.connect_to_device.end (res)) {
                    if (local_pane == null) {
                        window.remove (welcome);
                        add_panes ();
                    }
                    update_local_pane ();
                    update_remote_pane ();
                    connect_box.show_favorite_icon (
                        conn_saver.is_bookmarked (remote_access.get_uri ())
                    );
                    window.show_all ();
                } else {
                    welcome.title = "Could not connect to '" +
                        conn.hostname + ":" + conn.port.to_string () + "'";
                }
            });
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
            var pane_inner = new Gtk.Grid ();
            pane_inner.set_column_homogeneous (true);

            local_pane = new FilePane (true);
            pane_inner.add (local_pane);

            local_pane.row_clicked.connect ((name) => {
                local_access.goto_child (name);
                update_local_pane ();
            });

            local_pane.pathbar_activated.connect ((path) => {
                local_access.goto_path (path);
                update_local_pane ();
            });

            local_pane.file_dragged.connect ((uri) => {
            });

            remote_pane = new FilePane ();
            pane_inner.add (remote_pane);

            remote_pane.row_clicked.connect ((name) => {
                remote_access.goto_child (name);
                update_remote_pane ();
            });

            remote_pane.pathbar_activated.connect ((path) => {
                remote_access.goto_path (path);
                debug (remote_access.get_uri ());
                update_remote_pane ();
            });

            window.add (pane_inner);
        }

        private void update_local_pane () {
            var local_uri  = local_access.get_uri ();
            local_access.get_file_list.begin ((obj, res) => {
                var local_files = local_access.get_file_list.end (res);
                local_pane.update_list (local_files);
                local_pane.update_pathbar (local_uri);
            });
        }

        private void update_remote_pane () {
            var remote_uri  = remote_access.get_uri ();
            remote_access.get_file_list.begin ((obj, res) => {
                var remote_files = remote_access.get_file_list.end (res);
                remote_pane.update_list (remote_files);
                remote_pane.update_pathbar (remote_uri);
            });
        }

        private void setup_window () {
            window.default_width = 650;
            window.default_height = 550;
            window.set_titlebar (header_bar);
            window.show_all ();
        }
    }
}
