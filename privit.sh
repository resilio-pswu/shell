chown -R rslsync:rslsync *

for file in `ls -la | awk '/^-/{print $NF}'`
do
    chmod 664 file

done