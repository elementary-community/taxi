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
		mode_switch.bind_property ("active", settings, "dark-mode");
		mode_switch.notify.connect (() => {
			Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_mode;
		});
		
		if (settings.dark_mode) {
			mode_switch.active = true;
		}

		var new_window_item = new Gtk.ModelButton ();
		set_button_grid (new_window_item, _("New Window"), "Ctrl+N");

		var new_connection_item = new Gtk.ModelButton ();
		set_button_grid (new_connection_item, _("New Connection"), "Ctrl+Shift+N");

		var quit_item = new Gtk.ModelButton ();
		set_button_grid (quit_item, _("Quit"), "Ctrl+Q");

		var menu_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
		menu_separator.margin_top = 6;
		menu_separator.margin_bottom = 6;

		var menu_grid = new Gtk.Grid ();
		menu_grid.expand = true;
		menu_grid.margin_top = 3;
		menu_grid.margin_bottom = 3;
		menu_grid.orientation = Gtk.Orientation.VERTICAL;

		menu_grid.attach (new_window_item, 0, 1, 1, 1);
		menu_grid.attach (new_connection_item, 0, 2, 1, 1);
		menu_grid.attach (menu_separator, 0, 3, 1, 1);
		menu_grid.attach (quit_item, 0, 4, 1, 1);
		menu_grid.show_all ();

		var menu_button = new Gtk.MenuButton ();
		menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
		menu_button.tooltip_text = _("Menu");

		var menu_popover = new Gtk.Popover (null);
		menu_popover.add (menu_grid);
		
		menu_button.popover = menu_popover;
		menu_button.relief = Gtk.ReliefStyle.NONE;
		menu_button.valign = Gtk.Align.CENTER;
		
		var home_button = new Gtk.Button ();
		home_button.valign = Gtk.Align.CENTER;
		home_button.set_image (new Gtk.Image.from_icon_name ("go-home", Gtk.IconSize.LARGE_TOOLBAR));
		home_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Alt>1"}, _("Go Home"));
		
		var bookmark_button = new Gtk.Button ();
		bookmark_button.valign = Gtk.Align.CENTER;
		bookmark_button.set_image (new Gtk.Image.from_icon_name ("user-bookmarks", Gtk.IconSize.LARGE_TOOLBAR));
		bookmark_button.tooltip_text = _("Go Home");

		var separator1 = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		separator1.get_style_context ().add_class ("headerbar-separator");
		var separator2 = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		separator2.get_style_context ().add_class ("headerbar-separator");

		pack_start (home_button);
		pack_start (separator1);
		pack_start (bookmark_button);

		pack_end (menu_button);
		pack_end (separator2);
		pack_end (mode_switch);
	}

	private void set_button_grid (Gtk.ModelButton button, string text, string accelerator) {
		var button_grid = new Gtk.Grid ();

		var label = new Gtk.Label (text);
		label.expand = true;
		label.halign = Gtk.Align.START;
		label.margin_end = 10;

		var accel = new Gtk.Label (accelerator);
		accel.halign = Gtk.Align.END;
		accel.get_style_context ().add_class (Gtk.STYLE_CLASS_ACCELERATOR);

		button_grid.attach (label, 0, 0, 1, 1);
		button_grid.attach (accel, 1, 0, 1, 1);

		button.remove (button.get_child ());
		button.add (button_grid);
	}
}