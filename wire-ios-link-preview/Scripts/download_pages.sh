#!/bin/sh

export TEST_RESOURCES_DIR='WireLinkPreviewTests'
export USER_AGENT='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'

echo "Downloading sample pages"

curl -L -A "$USER_AGENT" http://www.theverge.com/2016/6/29/12054410/apple-tech-death-chart-headphone-jack-ports-usb-c > $TEST_RESOURCES_DIR/verge_full.txt
curl -L -A "$USER_AGENT" http://www.polygon.com/2016/7/11/12148448/which-pokemon-go-team-should-i-pick > $TEST_RESOURCES_DIR/polygon_full.txt
curl -L -A "$USER_AGENT" https://foursquare.com/neta_msf > $TEST_RESOURCES_DIR/foursquare_full.txt
curl -L -A "$USER_AGENT" http://www.theguardian.com/technology/2016/jul/01/tesla-autopilot-model-s-crash-how-does-it-work > $TEST_RESOURCES_DIR/guardian_full.txt
curl -L -A "$USER_AGENT" https://www.instagram.com/p/6AiRp5TOXB/ > $TEST_RESOURCES_DIR/instagram_full.txt
curl -L -A "$USER_AGENT" https://medium.com/wire-news/the-tune-for-this-summer-audio-filters-eca8cb0b4c57 > $TEST_RESOURCES_DIR/medium_full.txt
curl -L -A "$USER_AGENT" http://www.nytimes.com/2016/07/03/opinion/sunday/brazils-olympic-catastrophe.html > $TEST_RESOURCES_DIR/nytimes_full.txt
curl -L -A "$USER_AGENT" https://twitter.com/ericasadun/status/743868311843151872 > $TEST_RESOURCES_DIR/twitter_full.txt
curl -L -A "$USER_AGENT" https://twitter.com/ayanonagon/status/749726072623685632 > $TEST_RESOURCES_DIR/twitter_images_full.txt
curl -L -A "$USER_AGENT" https://vimeo.com/170888135 > $TEST_RESOURCES_DIR/vimeo_full.txt
curl -L -A "$USER_AGENT" https://www.washingtonpost.com/news/the-switch/wp/2016/07/12/holocaust-museum-to-visitors-please-stop-catching-pokemon-here > $TEST_RESOURCES_DIR/washington_post_full.txt
curl -L -A "$USER_AGENT" https://wire.com > $TEST_RESOURCES_DIR/wire_full.txt
curl -L -A "$USER_AGENT" https://www.youtube.com/watch?v=iAgKHSNqxa8 > $TEST_RESOURCES_DIR/youtube_full.txt
curl -L -A "$USER_AGENT" https://de.sports.yahoo.com/news/mario-gomez-besiktas-verl%c3%a4ngert-leihe-115423346.html > $TEST_RESOURCES_DIR/yahoo_sports_full.txt
curl -L -A "$USER_AGENT" https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521 > $TEST_RESOURCES_DIR/itunes_full.txt
curl -L -A "$USER_AGENT" https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521 > $TEST_RESOURCES_DIR/itunes_without_title_full.txt

pages=( "verge" "polygon" "foursquare" "guardian" "instagram" "medium" "nytimes" "twitter" "twitter_images" "vimeo" "washington_post" "wire" "youtube" "yahoo_sports" "itunes" "itunes_without_title")

echo "Processing sample pages..."

for i in "${pages[@]}"
do
	perl -0777 -pe 's/^.*?<head/<head/igs' $TEST_RESOURCES_DIR/${i}_full.txt | perl -0777 -pe 's/<\/head>.*$/<\/head>/igs' > $TEST_RESOURCES_DIR/${i}_head.txt
done

echo "Done"
