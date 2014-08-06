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

    public enum Protocol {

        FTP = 0,
        SFTP = 1,
        DAV = 2,
        AFP = 3;

        public string to_plain_text () {
            switch (this) {
                case Protocol.FTP: return "ftp";
                case Protocol.SFTP: return "sftp";
                case Protocol.DAV: return "dav";
                case Protocol.AFP: return "afp";
                default: return "ftp";
            }
        }
    }

    public interface IConnInfo : Object {

        /**
         *
         */
        public abstract Protocol protocol { get; set; default = Protocol.FTP; }

        /**
         *
         */
        public abstract string hostname { get; set; }

        /**
         *
         */
        public abstract int port { get; set; }

        /**
         *
         */
        public abstract string username { get; set; }

        /**
         *
         */
        public abstract string password { get; set; }

        /**
         *
         */
        public abstract bool anonymous { get; set; }

        /**
         *
         */
        public abstract bool remember { get; set; }

        /**
         *
         */
        public abstract string get_uri ();

        public abstract int get_default_port (Protocol protocol);
    }
}
