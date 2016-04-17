# DocSetsTake2

## What I did in this "take"

- Modified the canned Core Data code that Xcode provides.
	- Changed it to use hard-coded path to the docset's mom file.  Later realized I could have left the default code alone as far as loading the project's model -- I could (and did) import the docset's mom file into the project's model file.
	- Removed all write-related code, since I will be read-only.

- Did a test instantiation of the MOM, saw errors in the console about missing model classes, and how it would use NSManagedObject instead -- nice.

- Used mogenerator in a custom Xcode target to generate Core Data model classes.
	- See <http://raptureinvenice.com/getting-started-with-mogenerator/> and <http://stackoverflow.com/questions/3589247/how-do-the-mogenerator-parameters-work-which-can-i-send-via-xcode>.
	- `mogenerator --model DocSetsTake2/DocSetModel.xcdatamodeld --machine-dir DocSetsTake2/DocSetModel/Machine --human-dir DocSetsTake2/DocSetModel/Human --includeh DocSetsTake2/DocSetModel/DocSetModel.h --template-var arc=true`

- Added the mogenerated classes to the project.  Did a query for all tokens -- cool!


