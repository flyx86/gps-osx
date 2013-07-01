------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2000-2012, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

--  This package implements a text area target for the display of source
--  code.
--  It knows how to highlight keywords, strings and commands, and how
--  to display icons at the beginning of each line where a given function
--  returns True.
--  It also provides a source explorer that can quickly display and jump
--  in the various entities in the file (e.g procedures, types, ...).
--
--  Caches
--  =======
--
--  Some data is expensive to recompute for each file (e.g the list of lines
--  that contain code). We have thus implemented a system of caches so that
--  we don't need to recompute this data every time the file is reloaded.
--  This information is also computed in a lazy fashion, ie while nothing
--  else is happening in the application.

with Glib;
with Glib.Object;
with Gtk.Box;
with Gtkada.Types;
with GVD.Source_Editor;
with GVD.Types;
with Pango.Font;
with GNATCOLL.VFS;

package GVD.Code_Editors is

   type Code_Editor_Record is new Gtk.Box.Gtk_Hbox_Record with private;
   type Code_Editor is access all Code_Editor_Record'Class;

   procedure Gtk_New_Hbox
     (Editor      : out Code_Editor;
      Process     : access Glib.Object.GObject_Record'Class);
   --  Create a new editor window.
   --  The name and the parameters are chosen so that this type is compatible
   --  with the code generated by Gate for a Gtk_Box.

   procedure Initialize
     (Editor      : access Code_Editor_Record'Class;
      Process     : access Glib.Object.GObject_Record'Class);
   --  Internal procedure.

   procedure Show_Message
     (Editor      : access Code_Editor_Record;
      Message     : String);
   --  Display a message in the editor window.

   procedure Load_File
     (Editor      : access Code_Editor_Record;
      File_Name   : GNATCOLL.VFS.Virtual_File);
   --  Load and append a file in the editor.
   --  File_Name becomes the current file for the
   --  debugger (ie the one that contains the current execution line).

   procedure Set_Line
     (Editor  : access Code_Editor_Record;
      Line    : Natural;
      Process : Glib.Object.GObject);
   --  Set the current line (and draw the button on the side).
   --  Process is the Visual_Debugger which corresponds to the debugger
   --  that is stopped.

   procedure Update_Breakpoints
     (Editor    : access Code_Editor_Record;
      Br        : GVD.Types.Breakpoint_Array);
   --  Change the list of breakpoints to highlight in the editor (source and
   --  assembly editors).
   --  All the breakpoints that previously existed are removed from the screen,
   --  and replaced by the new ones.
   --  The breakpoints that do not apply to the current file are ignored.

   procedure Configure
     (Editor            : access Code_Editor_Record;
      Source            : GVD.Source_Editor.Source_Editor;
      Font              : Pango.Font.Pango_Font_Description;
      Current_Line_Icon : Gtkada.Types.Chars_Ptr_Array;
      Stop_Icon         : Gtkada.Types.Chars_Ptr_Array);
   --  Set the various settings of an editor.
   --  Source is the source editor associated with Editor.
   --  Ps_Font_Name is the name of the postscript font that will be used to
   --  display the text. It should be a fixed-width font, which is nice for
   --  source code.
   --  Default_Icon is used for the icon that can be displayed on the left of
   --  each line.
   --  Current_Line_Icon is displayed on the left of the line currently
   --  "active" (using the procedure Set_Line below).

   function Get_Line (Editor : access Code_Editor_Record) return Natural;
   --  Return the current line.

   type View_Mode is (Source, Asm, Source_Asm);
   --  Describe what kind of source is displayed by the code editor.

   procedure Set_Mode
     (Editor : access Code_Editor_Record;
      Mode   : View_Mode);
   --  Set the current view mode of Editor.

   function Get_Mode (Editor : access Code_Editor_Record) return View_Mode;
   --  Return the current view mode of Editor.

   function Get_Process
     (Editor : access Code_Editor_Record'Class) return Glib.Object.GObject;
   --  Return the process tab in which the editor is inserted.

   function Get_Source
     (Editor : access Code_Editor_Record'Class)
      return GVD.Source_Editor.Source_Editor;
   --  Return the widget used to display the source code

   function Get_Current_File
     (Editor : access Code_Editor_Record) return GNATCOLL.VFS.Virtual_File;
   --  Return the name of the currently edited file.
   --  "" is returned if there is no current file.

private

   type Code_Editor_Record is new Gtk.Box.Gtk_Hbox_Record with record
      Source      : GVD.Source_Editor.Source_Editor;

      Mode        : View_Mode := GVD.Code_Editors.Source;

      Source_Line : Natural;

      Process     : Glib.Object.GObject;
      --  The visual debugger associated with the editor
   end record;

end GVD.Code_Editors;
