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
        Gtk.Entry hostname_entry;
        ulong? handler;

        public ConnectBox () {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            set_spacing (0);
            set_homogeneous (false);
            build ();
        }

        public signal void connect_initiated (IConnInfo connect_details);
        public signal void bookmarked ();

        private void build () {
            pack_start (protocol_field (), true, true, 0);
            pack_start (hostname_field (), true, true, 0);
            get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        }

        private Gtk.ComboBoxText protocol_field () {
            protocol_combobox = combobox ({"FTP", "SFTP", "DAV", "AFP"});
            protocol_combobox.set_valign (Gtk.Align.CENTER);
            //if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.LTR) {
            //    protocol_combobox.set_direction (Gtk.TextDirection.RTL);
            //} else {
            //    protocol_combobox.set_direction (Gtk.TextDirection.LTR);
            //}
            return protocol_combobox;
        }

        private Gtk.Entry hostname_field () {
            hostname_entry = new Gtk.Entry ();
            hostname_entry.placeholder_text = "hostname:port";
            hostname_entry.set_max_width_chars (100000);
            hostname_entry.set_hexpand (true);
            hostname_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-next-symbolic");
            hostname_entry.activate.connect (this.submit_form);
            hostname_entry.icon_press.connect (this.submit_form);
            return hostname_entry;
        }

        private void submit_form () {
            var connect_data      = new ConnInfo ();
            var protocol          = (Protocol) protocol_combobox.get_active ();
            var hostname_port     = hostname_entry.get_text ().split (":", 2);
            var hostname          = hostname_port [0];
            var port              = (hostname_port.length == 2)?
                                      int.parse (hostname_port [1]) :
                                      connect_data.get_default_port (protocol);
            connect_data.protocol = protocol;
            connect_data.hostname = hostname;
            connect_data.port     = port;
            connect_initiated (connect_data);
        }

        private Gtk.ComboBoxText combobox (string[] entries) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                combobox.append_text (entry);
            }
            combobox.active = 0;
            return combobox;
        }

        public void show_favorite_icon (bool added = false) {
            var icon_name = added ?
                "starred-symbolic" :
                "non-starred-symbolic";
            hostname_entry.set_icon_from_icon_name (
                Gtk.EntryIconPosition.SECONDARY,
                icon_name
            );
            if (handler == null) {
                hostname_entry.icon_press.disconnect (this.submit_form);
                handler = hostname_entry.icon_press.connect (() => bookmarked ());
            }
        }

        public void show_spinner () {
        }

    }
}
