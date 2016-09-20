#!/bin/bash
# create chapters from .mp3
# install mplayer
# brew install mplayer

# for i in $(ls *.mp3);do ./podcastChapter.sh "$i"; done

# read podcast specific variables
source SETTINGS.sh # using source will run the file as if a script and save its variables

# recode input file
if [ -f "$1" ]; then
    # SET variables
    FILE="$1"
    EXT="${FILE##*.}"
    DIR=$(dirname "$1")
    DIRROOT=$(dirname "$0")
    NAME=$(basename "${FILE%.*}" | sed 's/_/\ /g')
    FILEINFO="${DIR}/${NAME}.info.txt"
    DATE=$(LANG=en_US.UTF-8 date +"%a, %d %b %y %H:%M:%S %z") # OSX fix
    LENGTH=$(ls -l "$FILE" | awk '{print $5}')
    PODCASTRSS="${DIRROOT}/${RSSNAME}"
    DURATION=""
    ALBUM="$TITLE"
    # GET INFO USING mplayer # http://stackoverflow.com/a/498138/1919382
   mplayer -vo null -ao null -frames 0 -identify -noautosub "$FILE" | cat > "$FILEINFO"
    if [ 0 != "$?" ]; then 
        echo "Mplayer error: $?"
        exit  
    fi
    
    ART=$(cat "$FILEINFO" | grep -i \ artist: | sed 's/.*:\ \(.*\)$/\1/')
    if [ 0 != ${#ART} ]; then
        ARTIST=$ART
    else
        echo "Artist not found, using default."
    fi
    ALB=$(cat "$FILEINFO" | grep -i \ album: | sed 's/.*:\ \(.*\)$/\1/')
    if [ 0 != ${#ALB} ]; then
        ALBUM=$ALB
    else
        echo "Album not found, using default."
    fi
    DUR=$(cat "$FILEINFO" | grep -i ID_LENGTH | sed 's/.*=\(.*\)/\1/')
    if [ 0 != ${#DUR} ]; then
        DURATION=$DUR
    else
        echo "Length in seconds not found, using default."
    fi
   
    case "$EXT" in
    mp3)  TYPE="audio/mpeg"
        ;;
    m4a)  TYPE="audio/x-m4a"
        ;;
    m4b)  TYPE="audio/x-m4a"
        ;;
    *) echo "Extension is not a supported audio file ($EXT)"
       exit
       ;;
    esac
    
    # Create URL using SETTINGS file
    URL="$SERVERURL"/"$FILE"

	# CREATE RSS OUTPUT
	# First check if mean rss file exists
	if [[ ! $(grep -c '<!-- insert new episode here -->' "$PODCASTRSS") -gt 0 ]]; then
		# create a new rss file
		cat <<EOF > "$PODCASTRSS"
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
<channel>
<title>"$TITLE"</title>
<link>"$LINK"</link>
<language>en-us</language>
<copyright>"$COPYRIGHT"</copyright>
<itunes:subtitle>"$SUBTITLE"</itunes:subtitle>
<itunes:author>"$ARTIST"</itunes:author>
<itunes:summary>"$SUMMARY"</itunes:summary>
<description>"$SUMMARY"</description>
<itunes:owner>
<itunes:name>"$OWNERNAME"</itunes:name>
<itunes:email>"$OWNEREMAIL"</itunes:email>
</itunes:owner>
<itunes:image href="$IMGURL" />
<!-- http://validator.w3.org/feed/docs/error/InvalidItunesCategory.html -->
<itunes:category text="$CATEGORY" />

<!-- insert new episode here -->

</channel>
</rss>
EOF
	fi
	
	# <item>
	# <title>Command Authority</title>
	# <itunes:author>Tom Clancy</itunes:author>
	# <itunes:subtitle>Tom Clancy - Command Authority - 2013</itunes:subtitle>
	# <itunes:summary>There’s a new strong man in Russia but his rise to power is based on a dark secret hidden decades in the past. The solution to that mystery lies with a most unexpected source—President Jack Ryan.</itunes:summary>
	# <itunes:image href="https://www.dropbox.com/s/ci4s6kd9r9mjax3/Command%20Authority.jpg?dl=1" />
	# <enclosure url="https://dl.dropbox.com/s/etcetc.mp3?dl=1" length="534996171" type="audio/mpeg" />
	# <guid>https://dl.dropbox.com/s/enum4zq6l9orooo/Command%20Authority.mp3?dl=1</guid>
	# <pubDate>Sat, 04 Jan 14 18:47:12 +0100</pubDate>
	# <itunes:duration>64418</itunes:duration>
	# </item>

    # CREATE OUTPUT 
  	ITEM=$(echo '
    <item>
    <title>'$NAME'</title>
    <itunes:author>'$ARTIST'</itunes:author>
    <itunes:subtitle>'$ALBUM'</itunes:subtitle>
    <itunes:summary>'$FILE - $SUMMARY'</itunes:summary>
    <enclosure url="'$URL'" length="'$LENGTH'" type="'$TYPE'" />
    <guid>'$URL'</guid>
    <pubDate>'$DATE'</pubDate>
    <itunes:duration>'$DURATION'</itunes:duration>
    </item>')
    
	# add line to bottom of $PODCASTRSS feed: <!-- insert new episode here -->
	cp "$PODCASTRSS" ."$PODCASTRSS".backup
	cat $PODCASTRSS | grep -B 999999 '<!-- insert new episode here -->$' | ghead -n -1 > podcast.tmp.rss
	echo "$ITEM" >> podcast.tmp.rss
	echo '<!-- insert new episode here -->
	</channel>
	</rss>' >> podcast.tmp.rss
	mv podcast.tmp.rss $PODCASTRSS
	echo "Added:"
	tail -n 15 $PODCASTRSS
	sleep 1 # added 1 second to get the timestamps at least 1 sec different the the podcasts appear in order
else
    echo "Usage:"
    echo "    $(basename $0) local.mp3 <link.mp3>"
    echo "or ..."
    echo "    find . -iname '*.mp3' -exec ./podcastChapter.sh {} \;"
    echo "    (order of results will determine the order of the rss feed.)"
fi
