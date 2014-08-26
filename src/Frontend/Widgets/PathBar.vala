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

    class PathBar : Gtk.Box {

        Location location = Location.LOCAL;

        public signal void navigate (string path);
        public signal void transfer ();

        public PathBar () {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            homogeneous = false;
            spacing = 0;
        }

        public PathBar.from_uri (string uri) {
            this ();
            set_path_helper (uri);
        }

        private string concat_until (string[] words, int n) {
            var result = "";
            for (int i = 0; (i < n + 1) && (i < words.length); i++) {
                result += words [i] + "/";
            }
            return result;
        }

        private void add_path_frag (string child, string path) {
            Gtk.Button button;
            if (path == "/") {
                button = new Gtk.Button.from_icon_name (
                    child,
                    Gtk.IconSize.MENU
                );
            } else {
                button = new Gtk.Button.with_label (child);
                var sep = new Gtk.Label ("▸");
                add (sep);
            }
            button.set_relief (Gtk.ReliefStyle.NONE);
            button.get_style_context ().add_class ("path-button");
            button.set_data<string> ("path", path);
            button.clicked.connect (() => {
                navigate (button.get_data<string> ("path"));
                debug ("PROPERTY: " + button.get_data<string> ("path") + "\n");
            });
            add (button);
        }

        public void set_path (string uri) {
            clear_path ();
            //margin = 6;
            var uri_obj = new Soup.URI (uri);
            switch (uri_obj.get_scheme ()) {
                case "file":
                    add_path_frag ("drive-harddisk-symbolic", "/");
                    location = Location.LOCAL;
                    break;
                case "ftp":
                case "sftp":
                default:
                    add_path_frag ("folder-remote-symbolic", "/");
                    location = Location.REMOTE;
                    break;
            }
            set_path_helper (uri_obj.get_path ());
            pack_end (new_xfer_button ());
        }

        private void set_path_helper (string path) {
            string[] directories = path.split ("/");
            for (int i = 0; i < directories.length; i++) {
                if (directories [i] != "") {
                    add_path_frag (directories [i], concat_until (directories, i));
                }
            }
        }

        private void clear_path () {
            foreach (Gtk.Widget child in get_children ()) {
                remove (child);
            }
            margin = 0;
        }

        private Gtk.Button new_xfer_button () {
            var xfer_icon_name = (location == Location.LOCAL)  ?
                                    "document-export-symbolic" :
                                    "document-import-symbolic" ;
            var xfer_button = new Gtk.Button.from_icon_name (
                xfer_icon_name,
                Gtk.IconSize.MENU
            );
            xfer_button.set_halign (Gtk.Align.END);
            xfer_button.set_relief (Gtk.ReliefStyle.NONE);
            xfer_button.clicked.connect (() => transfer ());
            return xfer_button;
        }
    }
}
