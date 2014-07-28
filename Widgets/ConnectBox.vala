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

    class ConnectBox : Gtk.Box {

        Gtk.ComboBoxText protocol_combobox;
        Gtk.Entry hostname_entry;


        public ConnectBox () {
            //get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);
            //set_orientation (Gtk.Orientation.HORIZONTAL);
            //set_spacing (0);
            //set_homogeneous (false);
            //expand = true;
            build ();
        }

        public signal void connect_initiated (IConnInfo connect_details);

        private void build () {
            pack_start (protocol_field (), true, true, 0);
            pack_start (hostname_field (), true, true, 0);
            get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        }

        private ComboBoxText protocol_field () {
            protocol_combobox = combobox ({"FTP", "SFTP"});
            protocol_combobox.set_valign (Gtk.Align.CENTER);
            protocol_combobox.get_style_context ().add_class ("button");
            return protocol_combobox;
        }

        private Gtk.Entry hostname_field () {
            hostname_entry = new Gtk.Entry ();            
            hostname_entry.placeholder_text = "example.com:port";
            hostname_entry.activate.connect (this.submit_form);
            hostname_entry.set_max_width_chars (100000);
            return hostname_entry;
        }
        
        private Gtk.Button right_button () {
            var connect_button = new Gtk.Button ();
            connect_button.add (new Gtk.Label (">"));
            connect_button.set_valign (Gtk.Align.CENTER);
            connect_button.clicked.connect (this.submit_form);
            return connect_button;
        }
        
        private void submit_form () {
            var connect_data       = new ConnInfo ();
            connect_data.protocol  = (Protocol) protocol_combobox.get_active ();
            connect_data.hostname  = hostname_entry.get_text ();
            connect_initiated (connect_data);
        }

        private ComboBoxText combobox (string[] entries) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                combobox.append_text (entry);
            }
            combobox.active = 0;
            return combobox;
        }
        

        
        /*
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
            var uri = remote_access.get_uri ();
            if (active) {
                if (!conn_saver.is_bookmarked (uri)) {
                    conn_saver.save (uri);
                }
                favorite_button.set_image (new Gtk.Image.from_icon_name (
                    "starred-symbolic",
                    IconSize.SMALL_TOOLBAR
                ));
            } else {
                if (conn_saver.is_bookmarked (uri)) {
                    conn_saver.remove (uri);
                }
                favorite_button.set_image (new Gtk.Image.from_icon_name (
                    "non-starred-symbolic",
                    IconSize.SMALL_TOOLBAR
                ));
            }
            update_saved_list ();
        }*/
    }
}
