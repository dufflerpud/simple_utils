# Here are some interesting files
**[add_header](#dt_86y8HF8yI)**:  Add Index, RCS ID, copyright, initial histories & doc to source<br>
**[anagram](#dt_86y8HF8yL)**:  Print anagrams of word specified in argument<br>
**[cat_media](#dt_86y8HJL7Q)**:  Concatinates different types of files (movies, pics, audio etc)<br>
**[copydb](#dt_86y8HJL7T)**:  Copy data from gdbm or perl objects to another db format<br>
**[count_domains](#dt_86y8HJL7W)**:  Read ip log file & count packets by domain<br>
**[descape](#dt_86y8HJL7Z)**:  Remove terminal control escape sequences from stdin<br>
**[doc_sep](#dt_86y8HJL7c)**:  Filter out all but the specified headers for documentation<br>
**[embed_images](#dt_86y8HJL7f)**:  Convert image URLs to the data they are pointing to<br>
**[fix_header](#dt_86y8HJL7i)**:  Add Index, RCS ID, copyright, initial histories & doc to source<br>
**[host_of_ssh](#dt_86y8HJL7l)**:  Print info about inbound SSH connections<br>
**[indent_json](#dt_86y8HJL7o)**:  Output json in a semi-readable (indented) format<br>
**[merge_scan_batch](#dt_86y8HJL7r)**:  Collect multiple pages into a single document<br>
**[mixtape](#dt_86y8HJL7u)**:  Create collections, or play randomly from collection<br>
**[nene](#dt_86y8HJL7x)**:  Copy data from any ext to any ext (converting as required)<br>
**[old_javascript](#dt_86y8HJL80)**:  Fix javascript to run on older engines<br>
**[radix](#dt_86y8HJL83)**:  Find all radices where number has specified digits<br>
**[remind](#dt_86y8HJL86)**:  Send e-mail reminders based on user's .remind<br>
**[rnh](#dt_86y8HJL89)**:  Simple file to manipulate old UNH runoff files.<br>
**[sanifile](#dt_86y8HJL8C)**:  Fix filenames to be UNIX friendly and convert to standard types<br>
**[scan](#dt_86y8HJL8F)**:  A friendly front end to scanimage to scan documents<br>
**[screens](#dt_86y8HJL8I)**:  Obtain info about connected monitors<br>
**[seconds_to_daytime](#dt_86y8HJL8L)**:  Convert seconds since epoch to readable format<br>
**[send_text](#dt_86y8HNXHQ)**:  Send a text to specified phone by e-mail to special address<br>
**[setup_access_point](#dt_86y8HNXHT)**:  Configure local WIFI card to be access point<br>
**[show](#dt_86y8HNXHW)**:  Play specified media on local display/speakers<br>
**[square_icon](#dt_86y8HNXHZ)**:  Create an icon suitable for iPhone based on supplied text<br>
**[sudoinstall](#dt_86y8HNXHc)**:  Try to install something.  I fail, sudo and try again.<br>
**[sumdir](#dt_86y8HNXHf)**:  Create a file containing checksums of files in directory<br>
**[tmog](#dt_86y8HNXHi)**:  Type, Mode, Owner and Group - create specified file<br>
**[unique_name](#dt_86y8HNXHl)**:  Fill in unique digits to create a filename<br>
**[upend](#dt_86y8HNXHo)**:  Print lines with text reversed within the line<br>
**[words_with](#dt_86y8HNXHr)**:  Show words using specified letters<br>
**[youtube](#dt_86y8HNXHu)**:  Convenient interface yt-dlp to download youtube videos<br>
# <a name='dt_86y8HF8yI'>**add_header**</a>:  Add Index entry, RCS ID, copyright, preliminary
history & documentation to source.  More complex than at first
blush because it needs to figure out comment convention so that new
header doesn't change semantics of program.
# <a name='dt_86y8HF8yL'>**anagram**</a>:  Print anagrams of word specified in argument.
**Uses system english dictionary (/usr/share/dict/words).
# <a name='dt_86y8HJL7Q'>**cat_media**</a>:  Concatinates different types of files (movies, pics,
**audio etc).  Complex because videos may not be same aspect ratio,
**audios may have different sample rates, etc.
# <a name='dt_86y8HJL7T'>**copydb**</a>:  Copy data from gdbm or perl objects into another
**format. Easily extensible to copy SQL or other database formats
**#as cpi_db is extended.
# <a name='dt_86y8HJL7W'>**count_domains**</a>:  Read ip log file & count packets by domain
**Information assumed to be on standard in put.
# <a name='dt_86y8HJL7Z'>**descape**</a>:  Remove terminal control escape sequences from stdin.
**Useful for analyzing output from software that thinks it is being
**run interactively.
# <a name='dt_86y8HJL7c'>**doc_sep**</a>:  Filter out all but the specified headers for documentation.
**Can also be used to remove documentation to leave just source
# <a name='dt_86y8HJL7f'>**embed_images**</a>:  Convert image URLs to the data they are pointing to.
**Useful for creating html that doesn't require internet connection.
# <a name='dt_86y8HJL7i'>**fix_header**</a>:  Add Index entry, RCS ID, copyright, preliminary
history & documentation to source.  More complex than at first
blush because it needs to figure out comment convention so that new
header doesn't change semantics of program.
# <a name='dt_86y8HJL7l'>**host_of_ssh**</a>:  Print info about inbound SSH connections.
**Filters output of lsof.
# <a name='dt_86y8HJL7o'>**indent_json**</a>:  Output json in a semi-readable (indented) format.
**Note that there are more standard libraries for doing this
**but the developer wasn't wild about the format.
# <a name='dt_86y8HJL7r'>**merge_scan_batch**</a>:  Collect multiple pages into a single document
**Generally takes a bunch of .pnm files to create a .pdf files, but
**input can be any single-page-images.  Smart enough to order PDF
**pages based on images scanned from two sided documents.
# <a name='dt_86y8HJL7u'>**mixtape**</a>:  Create music collections, or play randomly from collection
**or simply play random music from a specified directory.
# <a name='dt_86y8HJL7x'>**nene**</a>:  Copy data from any ext to any ext (converting as required)
**More complex than you might think.  For instance, if you nene a
**.txt file to a .mp3 file, you'll get the words in the .txt file
**in spoken English.  If you nene from a movie to a sound file,
**you'll just get the sound track.  Smarter than your average bear
**but frequently wrong.
# <a name='dt_86y8HJL80'>**old_javascript**</a>:  Fix javascript to run on old iPads due to syntax
**"for( const x of" and "for( const x in" syntax newer than those
**machines.
# <a name='dt_86y8HJL83'>**radix**</a>:  Find all radices where number has specified digits
**Radices from 2 to 62 checked.
# <a name='dt_86y8HJL86'>**remind**</a>:  Send e-mail reminders based on user's .remind
**Invoked once a day in the wee hours of the morning.
#Remind - Software to send e-mail reminders according to dated entries
# <a name='dt_86y8HJL89'>**rnh**</a>:  Simple file to manipulate old UNH runoff files.
# <a name='dt_86y8HJL8C'>**sanifile**</a>:  Fix filenames to be UNIX friendly and convert to standard types
**For instance, the standard movie is quicktime .mov.
**The standard for still pics are jpegs.
**The standard for still audo is mp3, etc.
**Convenient to apply to directories to quickly make sense of them.
# <a name='dt_86y8HJL8F'>**scan**</a>:  A friendly front end to scanimage to scan documents
**Uses merge_scan_batch and cat_media to construct pdf files.
# <a name='dt_86y8HJL8I'>**screens**</a>:  Obtain info about connected monitors.
**Interfaces with X via xrandr.
# <a name='dt_86y8HJL8L'>**seconds_to_daytime**</a>:  Convert seconds since epoch to readable format
# <a name='dt_86y8HNXHQ'>**send_text**</a>:  Send a text to specified phone by e-mail to special address
**Really just a front end to e-mail.
# <a name='dt_86y8HNXHT'>**setup_access_point**</a>:  Configure local WIFI card to be access point
# <a name='dt_86y8HNXHW'>**show**</a>:  Play specified media on local display/speakers
# <a name='dt_86y8HNXHZ'>**square_icon**</a>:  Create an icon suitable for iPhone based on supplied text
# <a name='dt_86y8HNXHc'>**sudoinstall**</a>:  Try to install something.  I fail, sudo and try again.
**A utility to run the install command, usually used by Makefile.	#
**Attempts the install first, and if it fails, does the same	#
**command under sudo.  Prevents user from having to become root	#
**just to do an install (all they need to do is type in their	#
**password).  If Makefile is already running as root		#
**presumably the install won't fail, so we don't do a sudo.	#
# <a name='dt_86y8HNXHf'>**sumdir**</a>:  Create a file containing checksums of files in directory
# <a name='dt_86y8HNXHi'>**tmog**</a>:  Type, Mode, Owner and Group - create specified file
**Similar to linux install utility but a lot faster to type
**because if can look at the arguments to know whether they apply
**to the file type, its mode etc.
# <a name='dt_86y8HNXHl'>**unique_name**</a>:  Fill in unique digits to create a filename
**Create a unique name for a file based on % notation in the
**supplied name.
# <a name='dt_86y8HNXHo'>**upend**</a>:  Print lines with text reversed within the line
# <a name='dt_86y8HNXHr'>**words_with**</a>:  Show words using specified letters
# <a name='dt_86y8HNXHu'>**youtube**</a>:  Convenient interface yt-dlp to download youtube videos
**In particular, maintain a list of files (youtube.list) in CWD
**with media and where it came from.
