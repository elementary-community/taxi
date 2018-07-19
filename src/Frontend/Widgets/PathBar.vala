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
    class PathBar : Gtk.Grid {
        public bool transfer_button_sensitive { get; set; }

        private Soup.URI current_uri;

        public signal void navigate (Soup.URI uri);
        public signal void transfer ();

        public PathBar.from_uri (Soup.URI uri) {
            set_path (uri);
        }

        private string concat_until (string[] words, int n) {
            var result = "";
            for (int i = 0; (i < n + 1) && (i < words.length); i++) {
                result += words [i] + "/";
            }
            return result;
        }

        private void add_path_frag (string child, string path) {
            var button = new Gtk.Button ();

            if (path == "/") {
                button.image = new Gtk.Image.from_icon_name (child, Gtk.IconSize.MENU);
            } else {
                var label = new Gtk.Label (child);
                label.ellipsize = Pango.EllipsizeMode.MIDDLE;

                button.tooltip_text = child;
                button.add (label);

                var sep = new PathBarSeparator ();
                add (sep);
            }

            var button_style_context = button.get_style_context ();
            button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            button_style_context.add_class ("path-button");

            button.clicked.connect (() => {
                current_uri.set_path (path);
                navigate (current_uri);
            });
            add (button);
        }

        public void set_path (Soup.URI uri) {
            clear_path ();
            current_uri = uri;
            string transfer_icon_name;
            var scheme = uri.get_scheme ();
            switch (scheme) {
                case "file":
                    add_path_frag ("drive-harddisk-symbolic", "/");
                    transfer_icon_name = "document-export-symbolic";
                    break;
                case "ftp":
                case "sftp":
                default:
                    add_path_frag ("folder-remote-symbolic", "/");
                    transfer_icon_name = "document-import-symbolic";
                    break;
            }
            set_path_helper (uri.get_path ());

            var transfer_button = new Gtk.Button.from_icon_name (transfer_icon_name, Gtk.IconSize.MENU);
            transfer_button.halign = Gtk.Align.END;
            transfer_button.hexpand = true;
            transfer_button.sensitive = false;
            transfer_button.tooltip_text = _("Transfer");
            transfer_button.bind_property ("sensitive", this, "transfer-button-sensitive", GLib.BindingFlags.BIDIRECTIONAL);
            transfer_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            transfer_button.clicked.connect (() => transfer ());

            add (transfer_button);
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
