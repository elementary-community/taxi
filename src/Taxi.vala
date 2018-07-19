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

    class Taxi : Granite.Application {
        public Taxi () {
            Granite.Services.Logger.initialize (exec_name);
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
        }

        public static int main (string[] args) {
            var program = new Taxi ();
            return program.run (args);
        }

        protected override void activate () {
            var gui = new GUI (
                new LocalFileAccess (),
                new RemoteFileAccess (),
                new FileOperations (),
                new ConnectionSaver ()
            );
        }
    }
}
