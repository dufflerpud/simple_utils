# Documentation for Simple Utils
Each file is its own perl or bourne shell (or Bash) script.  The vast majority
of the perl programs use the [cpi] perl library,  Many of the perl programs
also use the [common] Makefiles to build and directories to login, etc.
<hr>

<table width=90% style='table-collapse:collapse'>
<tr><th align=left><a href='#dt_86yWmyIFC'>add_header</a></th><td>Add Index, RCS ID, copyright, initial histories & doc to source</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFD'>anagram</a></th><td>Print anagrams of word specified in argument</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFE'>cat_media</a></th><td>Concatinates different types of files (movies, pics, audio etc)</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFF'>copydb</a></th><td>Copy data from gdbm or perl objects to another db format</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFG'>count_domains</a></th><td>Read ip log file & count packets by domain</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFH'>descape</a></th><td>Remove terminal control escape sequences from stdin</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFI'>doc_sep</a></th><td>Filter out all but the specified headers for documentation</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFJ'>embed_images</a></th><td>Convert image URLs to the data they are pointing to</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFK'>[fix_header](#dt_86yMzJIdb)</a></th><td>Add Index, RCS ID, copyright, initial histories & doc to source</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFL'>host_of_ssh</a></th><td>Print info about inbound SSH connections</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFM'>indent_json</a></th><td>Output json in a semi-readable (indented) format</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFN'>merge_scan_batch</a></th><td>Collect multiple pages into a single document</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFO'>mixtape</a></th><td>Create collections, or play randomly from collection</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFP'>nene</a></th><td>Copy data from any ext to any ext (converting as required)</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFQ'>old_javascript</a></th><td>Fix javascript to run on older engines</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFR'>radix</a></th><td>Find all radices where number has specified digits</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFS'>remind</a></th><td>Send e-mail reminders based on user's .remind</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFT'>rnh</a></th><td>Simple file to manipulate old UNH runoff files.</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFU'>sanifile</a></th><td>Fix filenames to be UNIX friendly and convert to standard types</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFV'>scan</a></th><td>A friendly front end to scanimage to scan documents</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFW'>screens</a></th><td>Obtain info about connected monitors</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFX'>seconds_to_daytime</a></th><td>Convert seconds since epoch to readable format</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFY'>send_text</a></th><td>Send a text to specified phone by e-mail to special address</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFZ'>setup_access_point</a></th><td>Configure local WIFI card to be access point</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFa'>show</a></th><td>Play specified media on local display/speakers</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFb'>square_icon</a></th><td>Create an icon suitable for iPhone based on supplied text</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFc'>sudoinstall</a></th><td>Try to install something.  I fail, sudo and try again.</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFd'>sumdir</a></th><td>Create a file containing checksums of files in directory</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFe'>tmog</a></th><td>Type, Mode, Owner and Group - create specified file</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFf'>unique_name</a></th><td>Fill in unique digits to create a filename</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFg'>upend</a></th><td>Print lines with text reversed within the line</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFh'>words_with</a></th><td>Show words using specified letters</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFi'>add_header</a></th><td>Add Index, RCS ID, copyright, initial histories & doc to source</td></tr>
<tr><th align=left><a href='#dt_86yWmyIFj'>youtube</a></th><td>Convenient interface yt-dlp to download youtube videos</td></tr>
</table>

<hr>


# <a id='dt_86yWmyIFC'>add_header</a>
Add Index entry, RCS ID, copyright, preliminary
history & documentation to source.  More complex than at first
blush because it needs to figure out comment convention so that new
header doesn't change semantics of program.

# <a id='dt_86yWmyIFD'>anagram</a>
Print anagrams of word specified in argument.
Uses system english dictionary (/usr/share/dict/words).

# <a id='dt_86yWmyIFE'>cat_media</a>
Concatinates different types of files (movies, pics,
audio etc).  Complex because videos may not be same aspect ratio,
audios may have different sample rates, etc.

# <a id='dt_86yWmyIFF'>copydb</a>
Copy data from gdbm or perl objects into another
format. Easily extensible to copy SQL or other database formats
#as cpi_db is extended.

# <a id='dt_86yWmyIFG'>count_domains</a>
Read ip log file & count packets by domain
Information assumed to be on standard in put.

# <a id='dt_86yWmyIFH'>descape</a>
Remove terminal control escape sequences from stdin.
Useful for analyzing output from software that thinks it is being
run interactively.

# <a id='dt_86yWmyIFI'>doc_sep</a>
Filter out all but the specified headers for documentation.
Can also be used to remove documentation to leave just source

# <a id='dt_86yWmyIFJ'>embed_images</a>
Convert image URLs to the data they are pointing to.
Useful for creating html that doesn't require internet connection.

# <a id='dt_86yWmyIFK'>[fix_header](#dt_86yMzJIdb)</a>
# <a name='dt_86yMzJIdb'>**fix_header**</a>:  Add Index entry, RCS ID, copyright, preliminary
history & documentation to source.  More complex than at first
blush because it needs to figure out comment convention so that new
header doesn't change semantics of program.

# <a id='dt_86yWmyIFL'>host_of_ssh</a>
Print info about inbound SSH connections.
Filters output of lsof.

# <a id='dt_86yWmyIFM'>indent_json</a>
Output json in a semi-readable (indented) format.
Note that there are more standard libraries for doing this
but the developer wasn't wild about the format.

# <a id='dt_86yWmyIFN'>merge_scan_batch</a>
Collect multiple pages into a single document
Generally takes a bunch of .pnm files to create a .pdf files, but
page-images.  Smart enough to order PDF
pages based on images scanned from two sided documents.

# <a id='dt_86yWmyIFO'>mixtape</a>
Create music collections, or play randomly from collection
or simply play random music from a specified directory.

# <a id='dt_86yWmyIFP'>nene</a>
Copy data from any ext to any ext (converting as required)
More complex than you might think.  For instance, if you nene a
.txt file to a .mp3 file, you'll get the words in the .txt file
in spoken English.  If you nene from a movie to a sound file,
you'll just get the sound track.  Smarter than your average bear
but frequently wrong.

# <a id='dt_86yWmyIFQ'>old_javascript</a>
Fix javascript to run on old iPads due to syntax
"for( const x of" and "for( const x in" syntax newer than those
machines.

# <a id='dt_86yWmyIFR'>radix</a>
Find all radices where number has specified digits
Radices from 2 to 62 checked.

# <a id='dt_86yWmyIFS'>remind</a>
Send e-mail reminders based on user's .remind
Invoked once a day in the wee hours of the morning.
Software to send e-mail reminders according to dated entries

# <a id='dt_86yWmyIFT'>rnh</a>
Simple file to manipulate old UNH runoff files.

# <a id='dt_86yWmyIFU'>sanifile</a>
Fix filenames to be UNIX friendly and convert to standard types
For instance, the standard movie is quicktime .mov.
The standard for still pics are jpegs.
The standard for still audo is mp3, etc.
Convenient to apply to directories to quickly make sense of them.

# <a id='dt_86yWmyIFV'>scan</a>
A friendly front end to scanimage to scan documents
Uses merge_scan_batch and cat_media to construct pdf files.

# <a id='dt_86yWmyIFW'>screens</a>
Obtain info about connected monitors.
Interfaces with X via xrandr.

# <a id='dt_86yWmyIFX'>seconds_to_daytime</a>
Convert seconds since epoch to readable format

# <a id='dt_86yWmyIFY'>send_text</a>
Send a text to specified phone by e-mail to special address
mail.

# <a id='dt_86yWmyIFZ'>setup_access_point</a>
Configure local WIFI card to be access point

# <a id='dt_86yWmyIFa'>show</a>
Play specified media on local display/speakers

# <a id='dt_86yWmyIFb'>square_icon</a>
Create an icon suitable for iPhone based on supplied text

# <a id='dt_86yWmyIFc'>sudoinstall</a>
Try to install something.  I fail, sudo and try again.
A utility to run the install command, usually used by Makefile.	#
Attempts the install first, and if it fails, does the same	#
command under sudo.  Prevents user from having to become root	#
just to do an install (all they need to do is type in their	#
password).  If Makefile is already running as root		#
presumably the install won't fail, so we don't do a sudo.	#

# <a id='dt_86yWmyIFd'>sumdir</a>
Create a file containing checksums of files in directory

# <a id='dt_86yWmyIFe'>tmog</a>
Type, Mode, Owner and Group - create specified file
Similar to linux install utility but a lot faster to type
because if can look at the arguments to know whether they apply
to the file type, its mode etc.

# <a id='dt_86yWmyIFf'>unique_name</a>
Fill in unique digits to create a filename
Create a unique name for a file based on % notation in the
supplied name.

# <a id='dt_86yWmyIFg'>upend</a>
Print lines with text reversed within the line

# <a id='dt_86yWmyIFh'>words_with</a>
Show words using specified letters

# <a id='dt_86yWmyIFi'>add_header</a>
Add Index entry, RCS ID, copyright, preliminary
history & documentation to source.  More complex than at first
blush because it needs to figure out comment convention so that new
header doesn't change semantics of program.

# <a id='dt_86yWmyIFj'>youtube</a>
Convenient interface yt-dlp to download youtube videos
In particular, maintain a list of files (youtube.list) in CWD
with media and where it came from.

<hr>

Many of these tools are extremely specific to the environment the author was
working in or the projects involved.  Many started out very specific and got
generalized over time - sometimes way beyond how they will ever realistically
be used.
