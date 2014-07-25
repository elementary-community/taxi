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

    class GUI {

        Gtk.Window window;
        Gtk.HeaderBar header_bar;
        Gtk.ToggleButton select_button;
        Gtk.ToggleButton favorite_button;
        FilePane localPane;
        FilePane remotePane;
        IFileAccess remote_access;
        IFileAccess local_access;

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_panes ();
            update_local_pane ();
            setup_window ();
            Gtk.main ();
        }

        public void register_local_access (IFileAccess local_access) {
            this.local_access = local_access;
        }

        public void register_remote_access (IFileAccess remote_access) {
            this.remote_access = remote_access;

            this.remote_access.connected.connect (() => {
                remotePane.stop_spinner ();
                header_bar.set_subtitle (remote_access.get_uri ());
            });
        }

        private void add_header_bar () {
            header_bar = new Gtk.HeaderBar ();
            header_bar.title = "Shift";
            header_bar.show_close_button = true;
            add_connect_button ();
            add_select_button ();
            add_favorite_button ();
        }

        private void add_connect_button () {
            var connect_button = new Gtk.Button.with_label ("Connect…");
            header_bar.pack_start (connect_button);

            var popover = new ConnectDialog (connect_button);

            connect_button.clicked.connect (() => {
                popover.show_all ();
                select_button.set_active (false);
            });

            popover.connect_initiated.connect ((conn) => {
                remotePane.start_spinner ();
                remote_access.connect_to_device.begin (conn, (obj, res) => {
                    if (remote_access.connect_to_device.end (res)) {
                        update_remote_pane ();
                        favorite_button.set_sensitive (true);
                    }
                });
            });
        }

        private void remote_pane_disconnect () {
            favorite_button.set_sensitive (false);
            // remotePane.disconnect ();
        }

        private void add_select_button () {
            select_button = new Gtk.ToggleButton ();

            select_button.add (new Gtk.Image.from_icon_name (
                "object-select-symbolic",
                IconSize.SMALL_TOOLBAR
            ));

            select_button.toggled.connect (() => {
                activate_selection_mode (select_button.active);
            });

            header_bar.pack_end (select_button);
        }

        private void add_favorite_button () {
            favorite_button = new Gtk.ToggleButton ();
            favorite_button.set_sensitive (false);

            favorite_button.add (new Gtk.Image.from_icon_name (
                "non-starred-symbolic",
                IconSize.SMALL_TOOLBAR
            ));

            favorite_button.toggled.connect (() => {
                activate_favorite_mode (favorite_button.active);
            });


            header_bar.pack_end (favorite_button);
        }

        private void activate_favorite_mode (bool active) {
            if (active) {
                favorite_button.set_image (new Gtk.Image.from_icon_name (
                    "starred-symbolic",
                    IconSize.SMALL_TOOLBAR
                ));
            } else {
                favorite_button.set_image (new Gtk.Image.from_icon_name (
                    "non-starred-symbolic",
                    IconSize.SMALL_TOOLBAR
                ));
            }
        }

        private void activate_selection_mode (bool active) {
            // localPane.set_show_checkboxes (active);
            // remotePane.set_show_checkboxes (active);
            if (active) {
                header_bar.get_style_context ().add_class ("selection-mode");
                header_bar.set_title ("Select");
            } else {
                header_bar.get_style_context ().remove_class ("selection-mode");
                header_bar.set_title ("Shift");
            }
        }

        private void add_panes () {
            var pane_outer = new Granite.Widgets.ThinPaned ();
            pane_outer.set_position (200);
            add_source_list (pane_outer);

            var pane_inner = new Granite.Widgets.ThinPaned ();
            pane_outer.pack2 (pane_inner, true, false);

            localPane = new FilePane ();
            pane_inner.pack1 (localPane, true, false);

            localPane.row_clicked.connect ((name) => {
                local_access.goto_child (name);
                update_local_pane ();
            });

            localPane.pathbar_activated.connect ((path) => {
                local_access.goto_path (path);
                update_local_pane ();
            });

            remotePane = new FilePane ();
            pane_inner.pack2 (remotePane, true, false);

            remotePane.row_clicked.connect ((name) => {
                remote_access.goto_child (name);
                update_remote_pane ();
            });

            remotePane.pathbar_activated.connect ((path) => {
                remote_access.goto_path (path);
                debug (remote_access.get_uri ());
                update_remote_pane ();
            });

            window.add (pane_outer);
        }

        private void update_local_pane () {
            var local_path = local_access.get_path ();
            var local_uri  = local_access.get_uri ();
            local_access.get_file_list.begin (local_path, (obj, res) => {
                var local_files = local_access.get_file_list.end (res);
                localPane.update_list (local_files);
                localPane.update_pathbar (local_uri);
            });
        }

        private void update_remote_pane () {
            var remote_path = remote_access.get_path ();
            var remote_uri  = remote_access.get_uri ();
            remote_access.get_file_list.begin (remote_path, (obj, res) => {
                var remote_files = remote_access.get_file_list.end (res);
                remotePane.update_list (remote_files);
                remotePane.update_pathbar (remote_uri);
            });
        }

        private void add_source_list (Granite.Widgets.ThinPaned pane) {
            var source_list = new Granite.Widgets.SourceList ();
            var saved_category = new Granite.Widgets.SourceList.ExpandableItem ("Saved Sites");
            add_source_list_item ("ftp://hamp.al", saved_category);
            add_source_list_item ("sftp://snowy.cs.bris.ac.uk", saved_category);
            saved_category.expand_all (true, false);
            var root = source_list.root;
            root.add (saved_category);
            pane.pack1 (source_list, true, false);
        }

        private void add_source_list_item (string name,
            Granite.Widgets.SourceList.ExpandableItem expandable) {
            var source_list_item = new Granite.Widgets.SourceList.Item (name);
            expandable.add (source_list_item);
        }

        private void setup_window () {
            window.default_width = 900;
            window.default_height = 500;
            window.set_titlebar (header_bar);
            window.show_all ();
        }
    }
}
