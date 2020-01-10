#!/bin/bash

EXLIST_DIR=/home/ex2k
SCRIPT_DIR=/root/scripts
POSTFIX_DIR=/etc/postfix
FILENAME=e-mail.txt
FILETEST=e-mail.ok

function extract_valid_recipients {

cat $1 |tr -d \" | tr , \\n| tr \; \\n| tr -d '\r' | awk -F\: '/(SMTP|smtp):/ {printf("%s\tOK\n" ,$2)}' | tr -d '}' | grep -v -f $SCRIPT_DIR/blacklist > $2

}

[[ -s $EXLIST_DIR/$FILENAME ]] || exit 0

while [ ! -s $EXLIST_DIR/$FILEHASH ]; do
:
done

HASH1=$(cat $EXLIST_DIR/$FILEHASH|awk '{print $1}'|sed '1s/^\xEF\xBB\xBF//'|tr -d '\r')
HASH2=$(sha256sum $EXLIST_DIR/$FILENAME|awk '{print $1}'|tr a-z A-Z)

if [ "$HASH1" == "$HASH2" ]; then

    extract_valid_recipients $EXLIST_DIR/$FILENAME $SCRIPT_DIR/relay_recipients

#    if [ $? == 0 ]; then

        cat $SCRIPT_DIR/relay_recipients > $POSTFIX_DIR/relay_recipients

        [[ ! -f $EXLIST_DIR/$FILEHASH ]] || rm -f $EXLIST_DIR/$FILEHASH

        /usr/sbin/postmap hash:$POSTFIX_DIR/relay_recipients

        rm -f $EXLIST_DIR/$FILENAME

        echo Done!
#    else
#       echo 'Can not extract valid recipients'
#       exit 0

else
    echo File does not exist or is empty.

fi
