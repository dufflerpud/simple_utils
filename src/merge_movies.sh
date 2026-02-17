#!/bin/sh
#
#indx#	merge_movies - Create movie from audio and video files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	merge_movies - Create movie from audio and video files
########################################################################

PROG=`basename $0`
#TMP=/tmp/$PROG
TMP=./.$PROG.tmp

#########################################################################
#	Print a usage message and exit.					#
#########################################################################
usage()
    {
    cat <<EOF
$1

Usage:  $PROG in_video in_audio out_audiovideo
EOF
    exit 1
    }

#########################################################################
#	Say what we're going to do and do it.				#
#########################################################################
echodo()
    {
    echo "+ $*"
    eval "$*"
    }

#########################################################################
#	Output a status with time stamp.				#
#########################################################################
status()
    {
    date "+[%H:%M:%S $1]"
    }

#########################################################################
#	Generate a ffmpeg file list					#
#########################################################################
ffmpeg_list()
    {
    n=$1
    while (( n-- > 0 )) ; do
	echo "file '$2'"
    done
    }

#########################################################################
#	Get the duration of a file in seconds (with decimal point)	#
#########################################################################
duration()
    {
    ffprobe -i "$1" -show_entries format=duration -v quiet -of csv="p=0"
    }

#########################################################################
#	Make a movie merging video and audio.				#
#########################################################################
merge_video_audio()
    {
    video_file=$1
    audio_file=$2
    resulting_file=$3
    audio_length=`duration $audio_file`
    video_length=`duration $video_file`
    audio_loop=`dc -e "$video_length $audio_length / 1 + p"`
    video_loop=`dc -e "$audio_length $video_length / 1 + p"`
    if [ $audio_loop -lt 2 ] ; then
        audio_loop=1
    elif [ $video_loop -lt 2 ] ; then
        video_loop=1
    else
        audio_loop=1
	video_loop=1
    fi
    if ffprobe $video_file 2>&1 | grep -q Audio: ; then
	video_only_file=$TMP.video.mov
	status "Stripping audio from $video_file"
	echodo ffmpeg -loglevel fatal -y -i $video_file -an -c copy $video_only_file < /dev/null
    else
        video_only_file=$video_file
    fi
    if ffprobe $audio_file 2>&1 | grep -q Video: ; then
	audio_only_file=$TMP.audio.mov
	status "Stripping video from $audio_file"
	echodo ffmpeg -loglevel fatal -y -i $audio_file -vn -c copy $audio_only_file < /dev/null
    else
        audio_only_file=$audio_file
    fi
    ffmpeg_list $audio_loop $audio_only_file > $TMP.audio_list
    ffmpeg_list $video_loop $video_only_file > $TMP.video_list
    echo "audio length=$audio_length loop=$audio_loop video length=$video_length loop=$video_loop"
    status "Preparing movie $resulting_file looping $video_file $video_loop time and $audio_file $audio_loop time"
    echodo ffmpeg -loglevel error -y -f concat -safe 0 -i $TMP.video_list -f concat -safe 0 -i $TMP.audio_list -c copy -shortest $resulting_file < /dev/null
    }

[ "$#" -ne 3 ] && usage "Incorrect number of arguments."

merge_video_audio "$1" "$2" "$3"

exec rm -f $TMP.*
