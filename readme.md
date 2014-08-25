# Arizona RAP

Provide system to support both football and basketball RAP with minimal administrative work.

Heroku TZ has been set to America/Phoenix.

# TODO



* instructions for users/admin


* user profile area, allow for email address/cell/change pass/etc

* main body top padding
* player selection toggle/JS
* mobile views
* sidebar header graphic

* ~better navigation~
* post/message on forum automatically for sign up, ~results, pricing/game open for picks~
* write actual tests
* send texts if picks haven't been made

* ~show total cost on game pick page `if @pickset`~

# PRIOR TO LAUNCH

* comment `hash = {football: 14, basketball: 14}` in `lib/forum`
* uncomment line that makes the post
* empty database
* verify admin users


# required Environment Variables
MONGOLAB_URI=[mongolab URI]
RACK_ENV=development
SECRET=[any string]
board_username=[BDW name]
board_password=[BDW password]
