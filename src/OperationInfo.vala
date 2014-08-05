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

    class OperationInfo : IOperationInfo, Object {

        private File source;

        private Cancellable? cancellable;

        public OperationInfo (File source, Cancellable? cancellable) {
            this.source = source;
            this.cancellable = cancellable;
        }

        public void cancel () {
            if (cancellable != null) {
                cancellable.cancel ();
            }
        }

        public string get_file_name () {
            return source.get_basename ();
        }

        public async Icon? get_file_icon () {
            Icon file_icon = null;
            try {
                var file_info = yield source.query_info_async (
                    "standard::icon",
                    FileQueryInfoFlags.NONE,
                    Priority.DEFAULT,
                    null
                );
                file_icon = file_info.get_icon ();
            } catch (Error e) {
                warning (e.message);
            }
            return file_icon;
        }
    }
}
