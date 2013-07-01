"""This plug-in provides menus to list unused entities

This menu adds some submenus to /Navigate that will show the list of entities
that are declared in the whole application, a specific project or a specific
file, and that are not used anywhere. In some cases, the compiler can warn
about unused entities local to a subprogram (or even to a package body in
Ada), but cannot do so for entities declared in specs.

The global entities that are not used anywhere will be listed in the locations
window, so that you can click on them to jump to their declaration.

For the time being, subprograms that are primitive operations of a tagged
type (or method of a class in languages other than Ada) are not listed, since
they might actually be called through dynamic dispatching and should not be
removed.

It is recommended that you remove all .ali files and then recompile your
application before running this script. It needs up to date cross-reference
information generated by the compiler. It will also read all .ali files it
finds in your object directories, so if you still have old files lying around,
they might show references to entities even though these entities are in fact
no longer used (which means GPS will not correctly report all cases of unused
entities).

Executing this script blocks the whole GPS interface, so it is normal that
GPS becomes unresponsive. Depending of the size of your project, this can
take a while to execute.
Note that you can save the contents of the Locations window, after execution,
through the GPS.Locations.dump() method in the python console.
"""


#############################################################################
## No user customization below this line
#############################################################################

from GPS import *

xmlada_projects=["xmlada_sax", "xmlada_dom", "xmlada_schema", "xmlada_unicode",
                 "xmlada_input", "xmlada_shared", "xmlada"]
aws_projects=["aws_config", "aws_libz", "aws_shared", "aws_ssl_support",
              "aws_components", "aws_xmlada", "aws"]

Preference ("Plugins/unused entities/ignoreprj").create (
  "Ignored projects", "string",
  """Comma-separated list of projects for which we never want to look for unused entities. # This should in general include those projects from third-party libraries. You can still search for unusued entities if you select that project
specifically.""",
  ",".join (xmlada_projects + aws_projects))

def EntityIterator (where):
  """Return all entities from WHERE"""
  if not where:
     ignore_projects = [s.strip().lower() for s in Preference ("Plugins/unused entities/ignoreprj").get().split(",")]

     for p in Project.root().dependencies (recursive=True):
       if p.name().lower() not in ignore_projects:
         Console ().write ("Searching unused entities in project " + p.name() + "\n")
         for s in p.sources ():
          for e in s.entities(local=True):
            yield e
  elif isinstance (where, Project):
    for s in where.sources():
       for e in s.entities(local=True):
          yield e
  elif isinstance (where, File):
    for e in where.entities(local=True):
      yield e


def GlobalIterator (where):
   """Return all global entities from WHERE"""
   for e in EntityIterator (where):
     if e.attributes()["global"]:
        yield e


def is_unused (entity):
   refs = entity.references \
      (include_implicit=True, synchronous=True, show_kind=True)
   for loc,kind in refs.iteritems():
     if kind != 'declaration' \
       and kind != 'body' \
       and kind != 'label':
        # Logger ("UNUSED").log (`entity` + " not unused because of " + `loc`)
        return False

   # If we have a primitive operation, do not report it for now, since it
   # might actually be called through dispatching. We do not know yet how
   # to test that

   if entity.primitive_of():
      return False

   #Logger ("UNUSED").log (`entity` + " is unused: " + `refs`)
   return True


def UnusedIterator (where, globals_only):
   """Return all unused entities from WHERE, and only global entities if
      GLOBALS_ONLY is true"""
   if globals_only:
      iter = GlobalIterator
   else:
      iter = EntityIterator

   for e in iter(where):
     if is_unused (e):
        yield e

def show_unused_entities (where, globals_only):
   """List all unused global entities from WHERE in the locations window"""
   Editor.register_highlighting ("Unused_Entities", "blue")
   Locations.remove_category ("Unused entity")
   MDI.get ("Messages").raise_window()

   # Update all xref information in memory, and then freeze db for efficiency
   # Note that one possible drawback is that this will read all .ali files in
   # the object directories, even if the source files no longer exist. So we
   # might be missing some cases of unused entities!

   Logger ("UNUSED").log ("starting")  # For timing and debugging
   Project.root().update_xref (recursive=True)
   Logger ("UNUSED").log ("done parsing")

   try:
     freeze_xref()
     set_busy()
     for e in UnusedIterator (where, globals_only=globals_only):
        Locations.add (category  = "Unused entity",
                       file      = e.declaration().file(),
                       line      = e.declaration().line(),
                       column    = e.declaration().column(),
                       message   = "unused entity " + e.name(),
                       highlight = "Unused_Entities",
                       length    = len (e.name()))

   finally:
     thaw_xref ()
     unset_busy()

   Console().write ("Done searching for unused entities\n")
   Logger ("UNUSED").log ("done")

def show_unused_entities_in_file (menu):
    show_unused_entities (EditorBuffer.get().file(), True)
def show_unused_entities_in_project (menu):
    show_unused_entities (EditorBuffer.get().file().project(), True)
def show_unused_entities_in_projects (menu):
    show_unused_entities (None, True)


Menu.create ("/Navigate/List unused entities/From file",
             on_activate=show_unused_entities_in_file,
             ref="Goto Body",
             add_before=False)
Menu.create ("/Navigate/List unused entities/From project",
             on_activate=show_unused_entities_in_project,
             ref="Goto Body",
             add_before=False)
Menu.create ("/Navigate/List unused entities/From all projects",
             on_activate=show_unused_entities_in_projects,
             ref="Goto Body",
             add_before=False)