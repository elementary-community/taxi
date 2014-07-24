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

    class PathBar : Gtk.ButtonBox {

        public signal void navigate (string path);

        public PathBar () {
            set_orientation (Orientation.HORIZONTAL);
            set_layout (ButtonBoxStyle.START);
            get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
            homogeneous = false;
            spacing = 0;
            margin = 6;
        }

        public PathBar.from_path (string path) {
            this ();
            setPathHelper (path);
        }

        private string concatUntil (string[] words, int n) {
            var result = "";
            for (int i = 0; (i < n + 1) && (i < words.length); i++) {
                result += words [i] + "/";
            }
            return result;
        }

        public void addChildDirectory (string child, string path) {
            var button = (path == "/") ?
                new Gtk.Button.from_icon_name (
                    "drive-harddisk-symbolic", IconSize.MENU) :
                new Gtk.Button.with_label (child);
            button.set_data<string> ("path", path);
            button.clicked.connect (() => {
                navigate (button.get_data<string> ("path"));
                debug ("PROPERTY: " + button.get_data<string> ("path") + "\n");
            });
            pack_start (button);
            set_child_non_homogeneous (button, true);
        }

        public void setPath (string path) {
            clearPath ();
            setPathHelper (path);
        }

        private void setPathHelper (string path) {
            addChildDirectory ("/", "/");
            string[] directories = path.split ("/");
            for (int i = 0; i < directories.length; i++) {
                if (directories [i] != "") {
                    addChildDirectory (directories [i], concatUntil (directories, i));
                }
            }
        }

        private void clearPath () {
            foreach (Widget child in get_children ()) {
                remove (child);
            }
        }
    }
}
