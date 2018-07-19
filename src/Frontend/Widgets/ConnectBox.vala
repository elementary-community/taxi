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

    class ConnectBox : Gtk.Box {

        Gtk.ComboBoxText protocol_combobox;
        Gtk.Entry path_entry;
        ulong? handler;
        bool show_fav_icon = false;
        bool added = false;

        public ConnectBox () {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            set_spacing (0);
            set_homogeneous (false);
            build ();
        }

        public signal void connect_initiated (Soup.URI uri);
        public signal void bookmarked ();
        public signal Soup.URI ask_hostname ();

        private void build () {
            pack_start (protocol_field (), true, true, 0);
            pack_start (hostname_field (), true, true, 0);
            get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        }

        private Gtk.ComboBoxText protocol_field () {
            protocol_combobox = combobox ({"FTP", "SFTP", "DAV", "AFP"});
            return protocol_combobox;
        }

        private Gtk.Entry hostname_field () {
            path_entry = new Gtk.Entry ();
            path_entry.placeholder_text = _("hostname:port/folder");
            path_entry.set_max_width_chars (100000);
            path_entry.set_hexpand (true);
            path_entry.activate.connect (this.submit_form);
            path_entry.changed.connect (this.on_changed);
            path_entry.focus_out_event.connect (this.on_focus_out);
            path_entry.grab_focus.connect_after (this.on_grab_focus);
            return path_entry;
        }

        private void submit_form () {
            var protocol = ((Protocol) protocol_combobox.get_active ()).to_plain_text ();
            var path = path_entry.get_text ();
            var uri = new Soup.URI (protocol + "://" + path);
            connect_initiated (uri);
        }

        private Gtk.ComboBoxText combobox (string[] entries) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                combobox.append_text (entry);
            }
            combobox.active = 0;
            return combobox;
        }

        private void on_changed () {
            var host_icon = path_entry.get_icon_name (Gtk.EntryIconPosition.SECONDARY);
            if (host_icon != "go-jump-symbolic") {
                path_entry.set_icon_from_icon_name (
                    Gtk.EntryIconPosition.SECONDARY,
                    "go-jump-symbolic"
                );
                if (handler != null) {
                    path_entry.disconnect (handler);
                }
                path_entry.icon_press.connect (this.submit_form);
            } else if (path_entry.get_text () == "") {
                if (show_fav_icon) {
                    show_favorite_icon (added);
                } else {
                    hide_host_icon ();
                }
            }
        }

        private bool on_focus_out () {
            if (path_entry.get_text () == "" && show_fav_icon) {
                var uri_reply = ask_hostname ();
                // TODO: Handle text changes in a less lazy way
                path_entry.changed.disconnect (this.on_changed);
                path_entry.set_text (uri_reply.to_string (false));
                path_entry.changed.connect (this.on_changed);
            }
            return false;
        }

        private void hide_host_icon () {
            path_entry.set_icon_from_icon_name (
                Gtk.EntryIconPosition.SECONDARY,
                null
            );
        }

        public void show_favorite_icon (bool added = false) {
            path_entry.icon_press.disconnect (this.submit_form);
            show_fav_icon = true;
            this.added = added;
            var icon_name = added ? "starred-symbolic" : "non-starred-symbolic";
            path_entry.set_icon_from_icon_name (
                Gtk.EntryIconPosition.SECONDARY,
                icon_name
            );
            if (handler != null) {
                path_entry.disconnect (handler);
            }
            handler = path_entry.icon_press.connect (() => {
                bookmarked ();
            });
        }

        public bool on_key_press_event (Gdk.EventKey event) {
            if (!path_entry.has_visible_focus ()) {
                path_entry.grab_focus ();
            }
            return false;
        }

        private void on_grab_focus () {
            path_entry.select_region (0, 0);
            path_entry.set_position (-1);
        }
    }
}
