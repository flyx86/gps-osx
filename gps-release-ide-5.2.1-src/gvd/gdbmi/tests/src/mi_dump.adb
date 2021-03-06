------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2011-2012, AdaCore                     --
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

with MI.Ast;
with MI.Ast.Pretty_Printers;
with MI.Lexer;
with MI.Parser;

with Ada.Command_Line;         use Ada.Command_Line;
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;

procedure MI_Dump is
   File         : File_Type;
   Token_List   : MI.Lexer.Token_List;
   Record_List  : MI.Ast.Record_List;
   V            : MI.Ast.Pretty_Printers.Default_Pretty_Printer;
   pragma Assert (Argument_Count = 1);

begin
   Open (File, In_File, Argument (1));
   Token_List := MI.Lexer.Build_Tokens (Stream (File));
   MI.Parser.Build_Records (Token_List, Record_List);
   V.Visit (Record_List);
   MI.Ast.Clear_Record_List (Record_List);
end MI_Dump;
