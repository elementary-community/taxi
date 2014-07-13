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

    public enum Protocol {
        FTP = 0,
        SFTP = 1;
    }

    class Connect {
        public Protocol protocol { get; set; default = Protocol.FTP; }
        public string hostname { get; set; }
        public int port { get; set; default = 21; }
        public string username { get; set; }
        public string password { get; set; }
        public bool anonymous { get; set; default = false; }

        public string get_protocol_string () {
            switch (protocol) {
                case Protocol.FTP: return "ftp";
                case Protocol.SFTP: return "sftp";
                default: return "ftp";
            }
        }

        public string get_uri () {
            return get_protocol_string () + "://" + hostname;
        }
    }

    class ConnectDialog : Gtk.Popover {

        public ConnectDialog (Gtk.Widget widget) {
            set_relative_to (widget);
            build ();
        }

        public signal void connect_initiated (Connect connect_details);

        private void build () {

            var grid = new Gtk.Grid ();
            this.add (alignment (grid, 6, 12, 12, 12));

            var row = 0;

            var label = new Gtk.Label ("Protocol");
            label.set_alignment (1.0f, 0.5f);
            grid.attach (label, 0, row, 1, 1);
            var protocol_combobox = combobox ({"FTP", "SFTP"});
            grid.attach (alignment (protocol_combobox, 6, 0, 6, 12), 1, row++, 1, 1);

            label = new Gtk.Label ("Hostname");
            label.set_alignment (1.0f, 0.5f);
            var hostname_entry = new Gtk.Entry ();
            hostname_entry.placeholder_text = "example.com";
            grid.attach (label, 0, row, 1, 1);
            grid.attach (alignment (hostname_entry, 6, 0, 6, 12), 1, row++, 2, 1);

            label = new Gtk.Label ("Port");
            label.set_alignment (1.0f, 0.5f);
            var port_entry = new Gtk.SpinButton.with_range (0, 50009, 1);
            port_entry.set_value (21);
            grid.attach (label, 0, row, 1, 1);
            grid.attach (alignment (port_entry, 6, 0, 6, 12), 1, row++, 1, 1);

            protocol_combobox.changed.connect (() => {
                switch ((Protocol) protocol_combobox.get_active ()) {
                    case Protocol.FTP:
                        port_entry.set_value (21);
                        break;
                    case Protocol.SFTP:
                        port_entry.set_value (22);
                        break;
                }
            });

            label = new Gtk.Label ("Anonymous");
            label.set_alignment (1.0f, 0.5f);
            var anonymous_switch = new Gtk.Switch ();
            grid.attach (label, 0, row, 1, 1);
            grid.attach (alignment (anonymous_switch, 6, 0, 6, 12), 1, row++, 1, 1);

            var username_label = new Gtk.Label ("Username");
            username_label.set_alignment (1.0f, 0.5f);
            var username_entry = new Gtk.Entry ();
            username_entry.placeholder_text = "Username";
            grid.attach (username_label, 0, row, 1, 1);
            grid.attach (alignment (username_entry, 6, 0, 6, 12), 1, row++, 2, 1);

            var password_label = new Gtk.Label ("Password");
            password_label.set_alignment (1.0f, 0.5f);
            var password_entry = new Gtk.Entry ();
            password_entry.placeholder_text = "Password";
            password_entry.set_visibility (false);
            grid.attach (password_label, 0, row, 1, 1);
            grid.attach (alignment (password_entry, 6, 0, 6, 12), 1, row++, 2, 1);

            anonymous_switch.notify["active"].connect (() => {
                if (anonymous_switch.get_active ()) {
                    password_label.set_sensitive (false);
                    username_label.set_sensitive (false);
                    username_entry.set_sensitive (false);
                    password_entry.set_sensitive (false);
                } else {
                    password_label.set_sensitive (true);
                    username_label.set_sensitive (true);
                    username_entry.set_sensitive (true);
                    password_entry.set_sensitive (true);
                }
            });

            var connect_button = new Gtk.Button ();
            connect_button.add (new Gtk.Label ("Connect"));
            connect_button.clicked.connect (() => {
                var connect_data  = new Connect ();
                connect_data.protocol = (Protocol) protocol_combobox.get_active ();
                connect_data.port = (int) port_entry.get_value ();
                connect_data.hostname = hostname_entry.get_text ();
                connect_data.username = username_entry.get_text ();
                connect_data.password = password_entry.get_text ();
                connect_data.anonymous = anonymous_switch.get_active ();
                connect_initiated (connect_data);
                this.hide ();
            });
            this.add (alignment_full (connect_button, 0, 12, 12, 12, 1.0f, 1.0f));
        }

        private ComboBoxText combobox (string[] entries) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                combobox.append_text (entry);
            }
            combobox.active = 0;
            return combobox;
        }

        private Alignment alignment_full (Widget widget, int top, int right,
            int bottom, int left, float xalign, float yalign) {

            var alignment = new Alignment (xalign, yalign, 0, 0);
            alignment.left_padding = left;
            alignment.right_padding = right;
            alignment.bottom_padding = bottom;
            alignment.top_padding = top;
            alignment.add (widget);
            return alignment;
        }

        private Alignment alignment (Widget widget, int top, int right,
            int bottom, int left) {

            return alignment_full (widget, top, right, bottom, left, 0.0f, 0.0f);
        }
    }
}
