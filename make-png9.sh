#!/bin/bash



# Functions used in the script
# ------------------------------------------------------------------------------

# Function to print usage report to stderr
function print_usage {
	cat - >&2 <<UsageDelimiter

$0: Creates a 9-patch PNG image from an input image.

Usage: $0 -i input.ipa -s <t-r-b-l> [options]
Options:
  -c <insets>       Specify the content-area insets. Defaults to the same area
                    as the stretchable-area if not supplied.
  -C <rectangle>    Specify the content-area rectangle. Defaults to the same
                    area as the stretchable-area if not supplied.
  -h                Show this help.
  -i <input_image>  Specify the input image (required).
  -o <output_image> The base-name of the output file, .9.png will be appended
                    automatically. Defaults to the base-name of the input file.
  -s <insets>       Specify the stretchable-area insets (-s or -S required).
  -S <rectangle>    Specify the stretchable-area rectangle (-s or -S required).

Insets or rectangle:
  The stretchable-area and content-area can be defined in two ways: As insets
  from the edge of the image; or as an absolute rectangle. Using insets is
  probably more useful in most cases because they represent the unstretchable
  or non-content areas at the edge of the image, regardless of the image size.

  Insets and rectangles are specified as four integer numbers separated by a
  dash (-). For insets the order is: top-right-bottom-left, for rectangles the
  order is x-y-width-height. For example insets of 2-4-6-8 on a 48x32 pixel
  image are equivalent to a rectangle of 8-2-24-36.

Usage examples:
$0 -i button.png -s 8-8-8-8
$0 -h

UsageDelimiter
}

# Function to print any error to stderr
function print_error {	# $1=theerror $2=printusage $3=exitcode
	echo "" >&2
	echo "$(tput bold)$(tput setaf 1)ERROR: $1$(tput sgr0)" >&2
	if [ $2 -ne 0 ]; then
		print_usage
	fi
	if [ $3 -ne 0 ]; then
		exit $3
	fi
}



# Start of script
# ------------------------------------------------------------------------------

# Init variables
help=0
error=""
INPUT_FILE=""
BASE_NAME=""
content_insets=0
content_rect=0
stretchable_insets=0
stretchable_rect=0

# Parse the options
while getopts ":c:C:hi:o:s:S:" opt; do
	case $opt in
	c)
		content_insets=1
		;;
	C)
		content_rect=1
		;;
	h)
		help=1
		;;
	i)
		INPUT_FILE="$OPTARG"
		;;
	o)
		BASE_NAME="$OPTARG"
		;;
	s)
		stretchable_insets=1
		;;
	S)
		stretchable_rect=1
		;;
	\?)
		error="Unrecognised option: -$OPTARG"
		;;
	:)
		error="You must specify an argument for the -$OPTARG option."
		;;
	esac
done

# Check for requesting help
if [ $help -ne 0 ]; then
	print_usage
	exit 0
fi

# Make sure we got all required arguments
if [ -z "$error" ]; then
	# Required: INPUT_FILE
	if [ -z $INPUT_FILE ]; then
		error="You must specify an input image file."
	fi
	# Required: stretchable-area
	if [ $stretchable_insets -eq 0 ] && [ $stretchable_rect -eq 0 ]; then
		error="You must specify the stretchable-area using either insets or rectangle"
	fi
	# Don't allow setting stretchable-area more than once
	if [ $stretchable_insets -ne 0 ] && [ $stretchable_rect -ne 0 ]; then
		error="You cannot set the stretchable-area using both insets and rectangle, use one or the other."
	fi
	# Don't allow setting content-area more than once
	if [ $content_insets -ne 0 ] && [ $content_rect -ne 0 ]; then
		error="You cannot set the content-area using both insets and rectangle, use one or the other."
	fi
fi

# Check for any errors
if [ -n "$error" ]; then
	print_error "$error" 1 1
fi

# We are good to go...
echo

