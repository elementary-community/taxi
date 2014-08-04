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

    class OperationsPopover : Gtk.Popover {

        Gtk.Grid grid = new Gtk.Grid ();
        Gee.Map<IOperationInfo, Gtk.Grid> operation_map
            = new Gee.HashMap <IOperationInfo, Gtk.Grid> ();
        Gtk.Label placeholder;

        public signal void operations_pending ();
        public signal void operations_finished ();

        public OperationsPopover (Gtk.Widget widget) {
            set_relative_to (widget);
            grid.set_orientation (Gtk.Orientation.VERTICAL);
            grid.margin = 12;
            placeholder = new Gtk.Label (_("No file operations are in progress"));
            add (grid);
            build ();
        }

        private void build () {
            grid.add (placeholder);
        }

        public void add_operation (IOperationInfo operation) {
            if (grid.get_child_at (0, 0) == placeholder) {
                grid.remove (placeholder);
                operations_pending ();
            }
            var row = new Gtk.Grid ();
            operation_map.set (operation, row);
            row.add (new Gtk.Label (operation.get_file_name ()));
            operation.get_file_icon.begin ((obj, res) => {
                row.add (
                    new Gtk.Image.from_gicon (
                        operation.get_file_icon.end (res),
                        Gtk.IconSize.DND
                    )
                );
            });
            grid.add (row);
        }

        public void remove_operation (IOperationInfo operation) {
            var row = operation_map.get (operation);
            grid.remove (row);
            operation_map.unset (operation);
            if (operation_map.size == 0) {
                operations_finished ();
                grid.add (placeholder);
            }
        }
    }
}
