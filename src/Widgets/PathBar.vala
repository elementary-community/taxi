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

    class PathBar : Gtk.ButtonBox {

        public signal void navigate (string path);

        public PathBar () {
            set_orientation (Gtk.Orientation.HORIZONTAL);
            set_layout (Gtk.ButtonBoxStyle.START);
            get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
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
            var button = (path == "/") ?
                new Gtk.Button.from_icon_name (
                    child, Gtk.IconSize.MENU) :
                new Gtk.Button.with_label (child);
            button.get_style_context ().add_class ("path-button");
            button.set_data<string> ("path", path);
            button.clicked.connect (() => {
                navigate (button.get_data<string> ("path"));
                debug ("PROPERTY: " + button.get_data<string> ("path") + "\n");
            });
            pack_start (button);
            set_child_non_homogeneous (button, true);
        }

        public void set_path (string uri) {
            clear_path ();
            //margin = 6;
            var uri_obj = new Soup.URI (uri);
            switch (uri_obj.get_scheme ()) {
                case "file":
                    add_path_frag ("drive-harddisk-symbolic", "/");
                    break;
                case "ftp":
                case "sftp":
                default:
                    add_path_frag ("folder-remote-symbolic", "/");
                    break;
            }
            set_path_helper (uri_obj.get_path ());
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
    }
}
