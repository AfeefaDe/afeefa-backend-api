# Migration for old Category translations to new Navigation structure
- Takes the category translations from the old phraseapp data
- matches them with the corresponding new navigation items
- creates a json files for each language to upload translated navigation items to phraseapp

## usage
- download old translation from phraseapp UI (locales view)
  - under File format select `Simple JSON`
  - under Tags choose `category` to get only the category (not the other UI stuff)
  - put into folder `/input`, e.g. `/input/english.json`
- get DB dump for new navigation items (including `legacy_title` for matching) and paste as PHP-var-format into file `migrate-old-categories-to-navigation.php`
- define all needed languages in file `migrate-old-categories-to-navigation.php`
- run `migrate-old-categories-to-navigation.php`
- generated json files can be found in folder `/output`
- upload file to phraseapp and WATCH OUT to __select the right locale when uploading__ and to __check "Update translations"__
