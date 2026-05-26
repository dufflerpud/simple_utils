/************************************************************************
 *indx#	fraction.c - Give fraction of time passed
 *@HDR@	$Id$
 *@HDR@
 *@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
 *@HDR@
 *@HDR@	Permission is hereby granted, free of charge, to any person
 *@HDR@	obtaining a copy of this software and associated documentation
 *@HDR@	files (the "Software"), to deal in the Software without
 *@HDR@	restriction, including without limitation the rights to use,
 *@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
 *@HDR@	sell copies of the Software, and to permit persons to whom
 *@HDR@	the Software is furnished to do so, subject to the following
 *@HDR@	conditions:
 *@HDR@	
 *@HDR@	The above copyright notice and this permission notice shall be
 *@HDR@	included in all copies or substantial portions of the Software.
 *@HDR@	
 *@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 *@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 *@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
 *@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 *@HDR@	OR OTHER DEALINGS IN THE SOFTWARE.
 *
 *hist#	2026-05-26 - Christopher.M.Caldwell0@gmail.com - Created
 ************************************************************************
 *doc#	fraction.c - Give fraction of time passed
 ************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char *progname;

void usage( const char *str, const char *arg )
    {
    fprintf(stderr,str,arg);
    fprintf(stderr,
        "\n\nUsage:  %s -t end_time [-n numerator][-d denominator]\n"
	"where end_time is the number of seconds to go\n"
	"where numerator is the maximum to force interval to print\n"
	"where denominator is the maximum to force interval to print\n",
        progname );
    exit(1);
    }

int main( int argc, const char *argv[] )
    {
    int end_time = 0;
    int numerator = -1;
    int denominator = -1;
    int i;

    if( (progname=strrchr(argv[0],'/')) )
        progname++;
    else
        progname = argv[0];

    for( i=1; i<argc; i++ )
        {
	char var = argv[i][1];
	int val;

	if( argv[i][0] != '-' || argv[i][2] != 0 )
	    usage("Illegal argument '%s'",argv[i]);
	else if( i >= (argc - 1) )
	    usage("%s requires an argument",NULL);
	else if( (val=atoi(argv[++i])) <= 0 )
	    usage("%s requires an integer argument",argv[i-1]);
	else if( var == 't' )
	    {
	    if( end_time > 0 )
	        usage("-t set multiple times",NULL);
	    else
		{
		const char *colon = strchr(argv[i],':');
		if( colon )
		    end_time = val*60 + atoi(colon+1);
		else
		    end_time = val;
		}
	    }
	else if( var == 'n' )
	    {
	    if( numerator >= -1 )
	        usage("-n set multiple times",NULL);
	    else
	        numerator = val;
	    }
	else if( var == 'd' )
	    {
	    if( denominator >= -1 )
	        usage("-d set multiple times",NULL);
	    else
	        denominator = val;
	    }
	else
	    usage("Unknown argument '%s'",argv[i-1]);
	}

    if( end_time <= 0 )		usage("No -t specified",NULL);
    if( denominator < 0 )	denominator = 10;
    if( numerator < 0 )		numerator = 1;

    int cur_time;
    for( cur_time=0; cur_time<=end_time; cur_time++ )
        {
	int div;
	for( div=cur_time; div>1; div-- )
	    {
	    if( ((end_time % div)==0) && ((cur_time % div)==0) )
	        {
		int top = cur_time / div;
		int bot = end_time / div;
		/* if( (top <= 2) || (top >= (bot-2)) || (bot <= 10) ) */
		if( bot < denominator ||
		    ( numerator>=0 && top<=numerator )		||
		    ( numerator>=0 && (bot-top)<=numerator)	)
		    {
		    printf("%02d:%02d %4d/%d\n",
		        cur_time/60,cur_time%60,top,bot);
		    break;
		    }
		}
	    }
	}
    return(0);
    }
