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

        construct {
            build_data_dir     = Constants.DATADIR;
            build_pkg_data_dir = Constants.PKGDATADIR;
            build_release_name = Constants.RELEASE_NAME;
            build_version      = Constants.VERSION;
            build_version_info = Constants.VERSION_INFO;
            program_name       = Constants.PROGRAM_NAME;
            exec_name          = Constants.EXEC_NAME;
            app_copyright      = "2014";
            app_years          = "2014";
            app_icon           = "taxi";
            app_launcher       = Constants.APP_LAUNCHER;
            main_url           = "http://launchpad.net/taxi";
            bug_url            = "http://bugs.launchpad.net/taxi";
            help_url           = "http://answers.launchpad.net/taxi";
            translate_url      = "http://translations.launchpad.net/taxi";
            about_authors      = {
                                    "Kiran John Hampal <kiran@elementaryos.org>"
                                 };
            about_documenters  = {};
            about_artists      = {
                                    "Kiran John Hampal <kiran@elementaryos.org>",
                                    "Daniel Fore <daniel@elementaryos.org>"
                                 };
            about_comments     = "";
            about_translators  = "";
            about_license      = "";
            about_license_type = Gtk.License.GPL_3_0;
        }

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
            gui.build ();
        }
    }
}
