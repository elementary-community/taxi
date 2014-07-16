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

    public class ConnInfo : IConnInfo, Object {
        public Protocol protocol { get; set; default = Protocol.FTP; }
        public string hostname { get; set; }
        public int port { get; set; default = 21; }
        public string username { get; set; }
        public string password { get; set; }
        public bool anonymous { get; set; default = false; }
        public bool remember { get; set; default = false; }

        private string get_protocol_string () {
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
}
