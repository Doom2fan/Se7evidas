#!/bin/bash

if [ -z ${S7PROG_GZDOOM+x} ]; then
	S7PROG_GZDOOM="gzdoom"
fi

if [ -z ${S7PROG_QZDOOM+x} ]; then
	S7PROG_QZDOOM="qzdoom"
fi

PROG_PROG=
PROG_ARGS=[]

PS3=
select opt in GZDoom QZDoom Exit
do
	case $opt in
		"GZDoom")
			PROG_PROG="$S7PROG_GZDOOM"
			PROG_ARGS=("-stdout" "-file 'PK3 Source'" "$S7_GZDOOMARGS" "$*")
			break
			;;
		"QZDoom")
			PROG_PROG="$S7PROG_QZDOOM"
			PROG_ARGS=("-stdout" "-file 'PK3 Source'" "$S7_QZDOOMARGS" "$*")
			break
			;;
		"Exit")
			exit
			;;
		*)
			echo "Invalid option $REPLY"
			;;
	esac
done

# WELL, IT WORKS.
# I CANNOT BE HELD RESPONSIBLE IF THE FOLLOWING LINE CAUSES ANY DAMAGE, DESTROYS YOUR COMPUTER OR SETS YOUR CAT AND/OR HAIR ON FIRE
echo $PROG_PROG "${PROG_ARGS[*]}" | $SHELL
