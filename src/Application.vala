/*
* Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>
* Copyright (c) 2018 Alecaddd (https://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
namespace Taxi {
	public Settings settings;
}

public class Taxi.Application : Gtk.Application {
	public GLib.List <Gtk.Window> windows;

	construct {
		application_id = "com.github.alecaddd.taxi";
		flags |= ApplicationFlags.FLAGS_NONE;

		settings = new Settings ();

		windows = new GLib.List <Gtk.Window> ();
	}

	public void new_window () {
        new Frontend.Window (this, new LocalFileAccess (),
								new RemoteFileAccess (),
								new FileOperations (),
								new ConnectionSaver ()).present ();
    }

    public override void window_added (Gtk.Window window) {
        windows.append (window as Gtk.Window);
        base.window_added (window);
	}
	
	public override void window_removed (Gtk.Window window) {
        windows.remove (window as Gtk.Window);
        base.window_removed (window);
    }

	protected override void activate () {
		var window = new Frontend.Window (this,
										new LocalFileAccess (),
										new RemoteFileAccess (),
										new FileOperations (),
										new ConnectionSaver ());

		window.show_all ();
	}

	public static int main (string[] args) {
		var application = new Application ();

		return application.run (args);
	}
}
