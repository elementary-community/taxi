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
        FilePane localPane;
        FilePane remotePane;

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_panes ();
            setup_window ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar = new Gtk.HeaderBar ();
            header_bar.title = "Shift";
            header_bar.show_close_button = true;
            add_connect_button ();
            add_app_menu ();
        }

        private void add_connect_button () {
            var connect_button = new Gtk.Button.with_label ("Connect…");
            header_bar.pack_start (connect_button);

            var popover = new ConnectDialog (connect_button);

            connect_button.clicked.connect (() => {
                popover.show_all ();
            });
        }

        private void add_app_menu () {
        }

        private void add_panes () {
            var pane_outer = new Granite.Widgets.ThinPaned ();
            pane_outer.set_position (200);
            add_source_list (pane_outer);

            var pane_inner = new Granite.Widgets.ThinPaned ();
            pane_outer.pack2 (pane_inner, true, false);

            localPane = new FilePane ();
            pane_inner.pack1 (localPane, true, false);

            remotePane = new FilePane ();
            pane_inner.pack2 (remotePane, true, false);

            window.add (pane_outer);
        }

        private void add_source_list (Granite.Widgets.ThinPaned pane) {
            var source_list = new Granite.Widgets.SourceList ();
            var saved_category = new Granite.Widgets.SourceList.ExpandableItem ("Saved Sites");
            add_source_list_item ("Test 1", saved_category);
            add_source_list_item ("Test 2", saved_category);
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
