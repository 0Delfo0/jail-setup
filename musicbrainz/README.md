# Musicbrainz Server iocage jail setup
This will setup a local slave mirror of the musicbrainz server, and configure it to start in fastcgi mode via nginx.

## Script configuration
+ There are a few variables that need to be set in setupjail.sh - do this first.
+ You need a Metabrainz Live Data Feed access token for access to the replication packets - https://musicbrainz.org/doc/Live_Data_Feed
+ This needs to be placed in musicbrainz_server/DBDefs.pm and please also set the public address for your server here or the CSS won't work

## Running the script
From a shell run:
sudo sh /path/to/apps/musicbrainz/setupjail.sh

I recommend using screen or tmux if you're doing this over ssh - it takes ages.

There will come a part when it is necessary to run a second script from inside the jail - you will be prompted.
