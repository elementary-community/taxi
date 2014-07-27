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

namespace Taxi {

    class Taxi : Granite.Application {

        construct {
            build_data_dir     = "";
            build_pkg_data_dir = "";
            build_release_name = "Prerelease";
            build_version      = "0.1";
            build_version_info = "";
            program_name       = "Taxi";
            exec_name          = "taxi";
            app_copyright      = "";
            app_years          = "2014";
            app_icon           = "";
            app_launcher       = "";
            main_url           = "http://hamp.al/shift";
            bug_url            = "http://hamp.al/shift";
            help_url           = "http://hamp.al/shift";
            translate_url      = "http://hamp.al/shift";
            about_authors      = {"Kiran John Hampal"};
            about_documenters  = {};
            about_artists      = {};
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
            //var settings = Gtk.Settings.get_default();
            //settings.gtk_application_prefer_dark_theme = true;
            var gui = new GUI ();
            gui.register_local_access (new LocalFileAccess ());
            gui.register_remote_access (new RemoteFileAccess ());
            gui.register_connection_saver (new ConnectionSaver ());
            gui.build ();
        }
    }
}
