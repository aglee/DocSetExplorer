# DocSetExplorer

DocSetExplorer is a learning tool I wrote to help myself explore the Core Data model that Apple uses in its docsets.  It won't have much use for you unless you happen to be interested in docset internals.  In particular, DocSetExplorer is not a general-purpose documentation browser.

If you are in fact interested in docset internals, you might want to look at the project's model file (DocSetModel.xcdatamodeld).  Use the Graph mode in Xcode's model editor.  I imported one of Apple's .mom files and teased apart all the boxes and arrows so you don't have to.  You'll see that the two primary entities are:

- Token, which represents an API symbol like a class name or function name, and
- Node, which represents a location in the documentation tree -- specifically, an anchor within an HTML file.

This file is included only for reference purposes.  When DocSetExplorer opens a docset, it uses the model file in the docset.

DocSetExplorer assumes you have a docset installed for at least one of Apple's SDKs (OSX, iOS, watchOS, or tvOS).  It looks for docsets in ~/Library/Developer/Shared/Documentation/DocSets, which is the standard place Xcode puts them.  There is a popup button in the upper left of the window that lets you select which docset you want to browse.


