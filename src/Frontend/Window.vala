/***
* Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>
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

class Taxi.Frontend.Window : Gtk.ApplicationWindow {
    public IConnectionSaver conn_saver { get; construct; }
    public IFileOperations file_operation { get; construct; }
    public IFileAccess local_access { get; construct; }
    public IFileAccess remote_access { get; construct; }

    private Granite.Widgets.Toast toast;
    private Gtk.Revealer spinner_revealer;
    private Gtk.Grid bookmark_list;
    private Gtk.Grid outer_box;
    private Gtk.MenuButton bookmark_menu_button;
    private Gtk.Stack alert_stack;
    private ConnectBox connect_box;
    private Granite.Widgets.Welcome welcome;
    private FilePane local_pane;
    private FilePane remote_pane;
    private Soup.URI conn_uri;
    private GLib.Settings saved_state;

    public Window (
        Gtk.Application application,
        IFileAccess local_access,
        IFileAccess remote_access,
        IFileOperations file_operation,
        IConnectionSaver conn_saver
    ) {
        Object (
            application: application,
            conn_saver: conn_saver,
            file_operation: file_operation,
            local_access: local_access,
            remote_access: remote_access
        );
    }

    construct {
        connect_box = new ConnectBox ();
        connect_box.valign = Gtk.Align.CENTER;

        var spinner = new Gtk.Spinner ();
        spinner.start ();

        var popover = new OperationsPopover (spinner);

        var operations_button = new Gtk.MenuButton ();
        operations_button.popover = popover;
        operations_button.valign = Gtk.Align.CENTER;
        operations_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        operations_button.add (spinner);

        spinner_revealer = new Gtk.Revealer ();
        spinner_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        spinner_revealer.add (operations_button);

        bookmark_list = new Gtk.Grid ();
        bookmark_list.margin_top = bookmark_list.margin_bottom = 3;
        bookmark_list.orientation = Gtk.Orientation.VERTICAL;

        var bookmark_scrollbox = new Gtk.ScrolledWindow (null, null);
        bookmark_scrollbox.hscrollbar_policy = Gtk.PolicyType.NEVER;
        bookmark_scrollbox.max_content_height = 500;
        bookmark_scrollbox.propagate_natural_height = true;
        bookmark_scrollbox.add (bookmark_list);
        bookmark_scrollbox.show ();

        var bookmark_popover = new Gtk.Popover (null);
        bookmark_popover.add (bookmark_scrollbox);

        bookmark_menu_button = new Gtk.MenuButton ();
        bookmark_menu_button.image = new Gtk.Image.from_icon_name ("user-bookmarks", Gtk.IconSize.LARGE_TOOLBAR);
        bookmark_menu_button.popover = bookmark_popover;
        bookmark_menu_button.tooltip_text = _("Access Bookmarks");

        update_bookmark_menu ();

        //  var header_bar = new Gtk.HeaderBar ();
        //  header_bar.set_show_close_button (true);
        //  header_bar.set_custom_title (new Gtk.Label (null));
        //  header_bar.pack_start (connect_box);
        //  header_bar.pack_start (spinner_revealer);
        //  header_bar.pack_start (bookmark_menu_button);
        var headerbar = new Frontend.Widgets.HeaderBar (this);

        welcome = new Granite.Widgets.Welcome (
            _("Connect"),
            _("Type a URL and press 'Enter' to\nconnect to a server.")
        );
        welcome.vexpand = true;

        local_pane = new FilePane ();
        local_pane.open.connect (on_local_open);
        local_pane.navigate.connect (on_local_navigate);
        local_pane.file_dragged.connect (on_local_file_dragged);
        local_pane.transfer.connect (on_remote_file_dragged);
        local_pane.@delete.connect (on_local_file_delete);
        local_access.directory_changed.connect (() => update_pane (Location.LOCAL));

        remote_pane = new FilePane ();
        remote_pane.open.connect (on_remote_open);
        remote_pane.navigate.connect (on_remote_navigate);
        remote_pane.file_dragged.connect (on_remote_file_dragged);
        remote_pane.transfer.connect (on_local_file_dragged);
        remote_pane.@delete.connect (on_remote_file_delete);

        alert_stack = new Gtk.Stack ();
        alert_stack.add (welcome);
        alert_stack.add (remote_pane);

        outer_box = new Gtk.Grid ();
        outer_box.add (local_pane);
        outer_box.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        outer_box.add (alert_stack);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (local_pane);
        size_group.add_widget (alert_stack);

        //  alert_stack = new Gtk.Stack ();
        //  alert_stack.add (welcome);
        //  alert_stack.add (outer_box);

        toast = new Granite.Widgets.Toast ("");

        var overlay = new Gtk.Overlay ();
        //  overlay.add (alert_stack);
        overlay.add (outer_box);
        overlay.add_overlay (toast);

        set_titlebar (headerbar);
        add (overlay);

        saved_state = new GLib.Settings ("com.github.alecaddd.taxi.state");

        var window_x = saved_state.get_int ("opening-x");
        var window_y = saved_state.get_int ("opening-y");

        if (window_x != -1 ||  window_y != -1) {
            move (window_x, window_y);
        }

        default_height = saved_state.get_int ("window-height");
        default_width = saved_state.get_int ("window-width");

        if (saved_state.get_boolean ("maximized")) {
            maximize ();
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/alecaddd/taxi/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        connect_box.connect_initiated.connect (on_connect_initiated);
        connect_box.ask_hostname.connect (on_ask_hostname);
        connect_box.bookmarked.connect (bookmark);

        file_operation.operation_added.connect (popover.add_operation);
        file_operation.operation_removed.connect (popover.remove_operation);
        file_operation.ask_overwrite.connect (on_ask_overwrite);

        key_press_event.connect (connect_box.on_key_press_event);

        popover.operations_pending.connect (show_spinner);
        popover.operations_finished.connect (hide_spinner);

        update_pane (Location.LOCAL);
    }

    private void on_connect_initiated (Soup.URI uri) {
        show_spinner ();
        remote_access.connect_to_device.begin (uri, this, (obj, res) => {
            if (remote_access.connect_to_device.end (res)) {
                alert_stack.visible_child = remote_pane;
                if (local_pane == null) {
                    key_press_event.disconnect (connect_box.on_key_press_event);
                }
                update_pane (Location.LOCAL);
                update_pane (Location.REMOTE);
                connect_box.show_favorite_icon (
                    conn_saver.is_bookmarked (remote_access.get_uri ().to_string (false))
                );
                conn_uri = uri;
            } else {
                alert_stack.visible_child = welcome;
                welcome.title = _("Could not connect to '%s'").printf (uri.to_string (false));
            }
            hide_spinner ();
        });
    }

    private void show_spinner () {
        spinner_revealer.reveal_child = true;
    }

    private void hide_spinner () {
        spinner_revealer.reveal_child = false;
    }

    private void bookmark () {
        var uri_string = conn_uri.to_string (false);
        if (conn_saver.is_bookmarked (uri_string)) {
            conn_saver.remove (uri_string);
        } else {
            conn_saver.save (uri_string);
        }
        connect_box.show_favorite_icon (
            conn_saver.is_bookmarked (uri_string)
        );
        update_bookmark_menu ();
    }

    private void update_bookmark_menu () {
        foreach (Gtk.Widget child in bookmark_list.get_children ()) {
            child.destroy ();
        }

        var uri_list = conn_saver.get_saved_conns ();
        if (uri_list.length () == 0) {
            bookmark_menu_button.sensitive = false;
        } else {
            foreach (string uri in uri_list) {
                var bookmark_item = new Gtk.ModelButton ();
                bookmark_item.text = uri;

                bookmark_list.add (bookmark_item);

                bookmark_item.clicked.connect (() => {
                    connect_box.go_to_uri (uri);
                });
            }
            bookmark_list.show_all ();
            bookmark_menu_button.sensitive = true;
        }
    }

    private void on_local_navigate (Soup.URI uri) {
        navigate (uri, local_access, Location.LOCAL);
    }

    private void on_local_open (Soup.URI uri) {
        local_access.open_file (uri);
    }

    private void on_remote_navigate (Soup.URI uri) {
        navigate (uri, remote_access, Location.REMOTE);
    }

    private void on_remote_open (Soup.URI uri) {
        remote_access.open_file (uri);
    }

    private void on_remote_file_dragged (string uri) {
        file_dragged (uri, Location.REMOTE, remote_access);
    }

    private void on_local_file_dragged (string uri) {
        file_dragged (uri, Location.LOCAL, local_access);
    }

    private void on_local_file_delete (Soup.URI uri) {
        file_delete (uri, Location.LOCAL);
    }

    private void on_remote_file_delete (Soup.URI uri) {
        file_delete (uri, Location.REMOTE);
    }

    private void navigate (Soup.URI uri, IFileAccess file_access, Location pane) {
        file_access.goto_dir (uri);
        update_pane (pane);
    }

    private void file_dragged (
        string uri,
        Location pane,
        IFileAccess file_access
    ) {
        var source_file = File.new_for_uri (uri.replace ("\r\n", ""));
        var dest_file = file_access.get_current_file ().get_child (source_file.get_basename ());
        file_operation.copy_recursive.begin (
            source_file,
            dest_file,
            FileCopyFlags.NONE,
            new Cancellable (),
            (obj, res) => {
                try {
                    file_operation.copy_recursive.end (res);
                    update_pane (pane);
                } catch (Error e) {
                    toast.title = e.message;
                    toast.send_notification ();
                }
            }
         );
    }

    private void file_delete (Soup.URI uri, Location pane) {
        var file = File.new_for_uri (uri.to_string (false));
        file_operation.delete_recursive.begin (
            file,
            new Cancellable (),
            (obj, res) => {
                try {
                    file_operation.delete_recursive.end (res);
                    update_pane (pane);
                } catch (Error e) {
                    toast.title = e.message;
                    toast.send_notification ();
                }
            }
        );
    }

    private void update_pane (Location pane) {
        IFileAccess file_access;
        FilePane file_pane;
        switch (pane) {
            case Location.REMOTE:
                file_access = remote_access;
                file_pane = remote_pane;
                break;
            case Location.LOCAL:
            default:
                file_access = local_access;
                file_pane = local_pane;
                break;
        }
        file_pane.start_spinner ();
        var file_uri = file_access.get_uri ();
        file_access.get_file_list.begin ((obj, res) => {
        var file_files = file_access.get_file_list.end (res);
            file_pane.stop_spinner ();
            file_pane.update_pathbar (file_uri);
            file_pane.update_list (file_files);
        });
    }

    private Soup.URI on_ask_hostname () {
        return conn_uri;
    }

    private int on_ask_overwrite (File destination) {
        var dialog = new Gtk.MessageDialog (
            this,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.QUESTION,
            Gtk.ButtonsType.NONE,
            _("Replace existing file?")
        );
        dialog.format_secondary_markup (
            _("<i>\"%s\"</i> already exists. You can replace this file, replace all conflicting files or choose not to replace the file by skipping.".printf (destination.get_basename ()))
        );
        dialog.add_button (_("Replace All Conflicts"), 2);
        dialog.add_button (_("Skip"), 0);
        dialog.add_button (_("Replace"), 1);
        dialog.get_widget_for_response (1).get_style_context ().add_class ("suggested-action");

        var response = dialog.run ();
        dialog.destroy ();
        return response;
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (is_maximized) {
            saved_state.set_boolean ("maximized", true);
        } else {
            saved_state.set_boolean ("maximized", false);

            int window_width, window_height;
            get_size (out window_width, out window_height);
            saved_state.set_int ("window-height", window_height);
            saved_state.set_int ("window-width", window_width);

            int x_pos, y_pos;
            get_position (out x_pos, out y_pos);
            saved_state.set_int ("opening-x", x_pos);
            saved_state.set_int ("opening-y", y_pos);
        }

        return base.configure_event (event);
    }
}
