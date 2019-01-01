/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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

class Taxi.Frontend.Widgets.HeaderBar : Gtk.HeaderBar {
    public weak Frontend.Window window { get; construct; }

    private Granite.ModeSwitch mode_switch;

    public HeaderBar (Frontend.Window main_window) {
		Object (window: main_window);

        show_close_button = true;
        custom_title = null;
    }
    
    construct {
        mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
		mode_switch.primary_icon_tooltip_text = _("Light Mode");
		mode_switch.secondary_icon_tooltip_text = _("Dark Mode");
		mode_switch.valign = Gtk.Align.CENTER;
		//  mode_switch.bind_property ("active", settings, "dark-theme");
		//  mode_switch.notify.connect (() => {
		//  	Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;
		//  });
		
		//  if (settings.dark_theme) {
		//  	mode_switch.active = true;
        //  }

        pack_end (mode_switch);
    }
}