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
        FilePane localPane;
        FilePane remotePane;
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
                remotePane.stop_spinner ();
            });
        }

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_panes ();
            update_local_pane ();
            setup_window ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar  = new HeaderBar ();
            connect_box = new ConnectBox ();
            header_bar.set_show_close_button (true);
            header_bar.set_custom_title (new Gtk.Label (null));
            header_bar.pack_start (connect_box);

            /*header_bar.connect_initiated.connect ((conn) => {
                remotePane.start_spinner ();
                remote_access.connect_to_device.begin (conn, (obj, res) => {
                    if (remote_access.connect_to_device.end (res)) {
                        update_remote_pane ();
                        favorite_button.set_active (
                            conn_saver.is_bookmarked (remote_access.get_uri ())
                        );
                    }
                });
            });*/
        }

        private void add_panes () {
            var pane_inner = new Gtk.Grid ();
            pane_inner.set_column_homogeneous (true);

            localPane = new FilePane ();
            pane_inner.attach (localPane, 0, 0, 1, 1);

            localPane.row_clicked.connect ((name) => {
                local_access.goto_child (name);
                update_local_pane ();
            });

            localPane.pathbar_activated.connect ((path) => {
                local_access.goto_path (path);
                update_local_pane ();
            });

            remotePane = new FilePane ();
            pane_inner.attach (remotePane, 1, 0, 1, 1);

            remotePane.row_clicked.connect ((name) => {
                remote_access.goto_child (name);
                update_remote_pane ();
            });

            remotePane.pathbar_activated.connect ((path) => {
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
                localPane.update_list (local_files);
                localPane.update_pathbar (local_uri);
            });
        }

        private void update_remote_pane () {
            var remote_uri  = remote_access.get_uri ();
            remote_access.get_file_list.begin ((obj, res) => {
                var remote_files = remote_access.get_file_list.end (res);
                remotePane.update_list (remote_files);
                remotePane.update_pathbar (remote_uri);
            });
        }

        private void setup_window () {
            window.default_width = 900;
            window.default_height = 500;
            window.set_titlebar (header_bar);
            window.show_all ();
        }
    }
}
