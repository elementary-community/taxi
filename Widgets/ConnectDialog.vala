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

    class ConnectDialog : Gtk.Popover {
    
        Gtk.Grid grid = new Gtk.Grid ();
        int row = 0;
        Gtk.ComboBoxText protocol_combobox;
        Gtk.SpinButton port_entry   = new Gtk.SpinButton.with_range (0, 50009, 1);
        Gtk.Entry hostname_entry    = new Gtk.Entry ();
        Gtk.Entry username_entry    = new Gtk.Entry ();
        Gtk.Entry password_entry    = new Gtk.Entry ();
        Gtk.Switch anonymous_switch = new Gtk.Switch ();
        Gtk.Label username_label    = new Gtk.Label ("Username");
        Gtk.Label password_label    = new Gtk.Label ("Password");


        public ConnectDialog (Gtk.Widget widget) {
            set_relative_to (widget);
            build ();
        }

        public signal void connect_initiated (IConnInfo connect_details);

        private void build () {
            grid = new Gtk.Grid ();
            grid.margin_left = 12;
            this.add (grid);
            var row = 0;
            add_protocol_field ();
            add_hostname_field ();
            add_port_field ();
            add_anon_field ();
            add_username_field ();
            add_password_field ();
            add_connect_button ();

        }
        
        private void add_protocol_field () {
            var label = new Gtk.Label ("Protocol");
            label.set_alignment (1.0f, 0.5f);
            grid.attach (label, 0, row, 1, 1);
            
            protocol_combobox = combobox ({"FTP", "SFTP"});
            protocol_combobox.margin_top = 12;
            protocol_combobox.margin_bottom = 6;
            protocol_combobox.margin_left = 12;
            protocol_combobox.margin_right = 12;  
            grid.attach (protocol_combobox, 1, row++, 1, 1);
        }
        
        private void add_hostname_field () {
            var label = new Gtk.Label ("Hostname");
            label.set_alignment (1.0f, 0.5f);
            grid.attach (label, 0, row, 1, 1);
            
            hostname_entry.margin_top = 6;
            hostname_entry.margin_bottom = 6;
            hostname_entry.margin_left = 12;
            hostname_entry.margin_right = 12;  
            hostname_entry.placeholder_text = "example.com";
            grid.attach (hostname_entry, 1, row++, 2, 1);
        }
        
        private void add_port_field () {
            var label = new Gtk.Label ("Port");
            label.set_alignment (1.0f, 0.5f);
            grid.attach (label, 0, row, 1, 1);
            
            port_entry.margin_top = 6;
            port_entry.margin_bottom = 6;
            port_entry.margin_left = 12;
            port_entry.margin_right = 12;   
            port_entry.set_value (21);
            grid.attach (port_entry, 1, row++, 1, 1);

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
        }
        
        private void add_anon_field () {
            var label = new Gtk.Label ("Anonymous");
            label.set_alignment (1.0f, 0.5f);
            grid.attach (label, 0, row, 1, 1);
            
            anonymous_switch.margin_top = 6;
            anonymous_switch.margin_bottom = 6;
            anonymous_switch.margin_left = 12;
            anonymous_switch.margin_right = 12;
            anonymous_switch.hexpand = false;
            anonymous_switch.halign = Align.START;
            grid.attach (anonymous_switch, 1, row++, 1, 1);
        }
        
        private void add_username_field () {
            username_label.set_alignment (1.0f, 0.5f);
            grid.attach (username_label, 0, row, 1, 1);
            
            username_entry.margin_top = 6;
            username_entry.margin_bottom = 6;
            username_entry.margin_left = 12;
            username_entry.margin_right = 12;
            username_entry.placeholder_text = "Username";
            grid.attach (username_entry, 1, row++, 2, 1);
        }
        
        private void add_password_field () {
            password_label.set_alignment (1.0f, 0.5f);
            grid.attach (password_label, 0, row, 1, 1);
            
            password_entry.margin_top = 6;
            password_entry.margin_bottom = 6;
            password_entry.margin_left = 12;
            password_entry.margin_right = 12;
            password_entry.placeholder_text = "Password";
            password_entry.set_visibility (false);        
            grid.attach (password_entry, 1, row++, 2, 1);

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
        }
        
        private void add_connect_button () {
            var connect_button = new Gtk.Button ();
            connect_button.add (new Gtk.Label ("Connect"));
            connect_button.margin_top = 6;
            connect_button.margin_bottom = 12;
            connect_button.margin_left = 12;
            connect_button.margin_right = 12;
            connect_button.get_style_context ().add_class ("suggested-action");
            grid.attach (connect_button, 2, row++, 1, 1);
            
            connect_button.clicked.connect (() => {
                var connect_data       = new ConnInfo ();
                connect_data.protocol  = (Protocol) protocol_combobox.get_active ();
                connect_data.port      = (int) port_entry.get_value ();
                connect_data.hostname  = hostname_entry.get_text ();
                connect_data.username  = username_entry.get_text ();
                connect_data.password  = password_entry.get_text ();
                connect_data.anonymous = anonymous_switch.get_active ();
                connect_initiated (connect_data);
                this.hide ();
            });
        }

        private ComboBoxText combobox (string[] entries) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                combobox.append_text (entry);
            }
            combobox.active = 0;
            return combobox;
        }
    }
}
