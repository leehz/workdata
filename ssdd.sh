ssh -qfTnN -D 1080 localhost

SCREEN -dm socat tcp-listen:1088,fork,reuseaddr tcp:localhost:1080
