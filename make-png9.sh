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
  -v                Be verbose.

Insets or rectangle:
  The stretchable-area and content-area can be defined in two ways: As insets
  from the edge of the image; or as an absolute rectangle. Using insets is
  probably more useful in most cases because they represent the unstretchable
  or non-content areas at the edge of the image, regardless of the image size.

  Insets and rectangles are specified as four integer numbers separated by a
  dash (-). For insets the order is: top-right-bottom-left, for rectangles the
  order is x-y-width-height. For example insets of 2-4-6-8 on a 32x32 pixel
  image are equivalent to a rectangle of 8-2-20-24.

Usage examples:
$0 -i button.png -s 8-8-8-8
$0 -h

UsageDelimiter
}

ANSI_bold="$(tput bold)"
ANSI_red="$(tput setaf 1)"
ANSI_green="$(tput setaf 2)"
ANSI_yellow="$(tput setaf 3)"
ANSI_blue="$(tput setaf 4)"
ANSI_magenta="$(tput setaf 5)"
ANSI_cyan="$(tput setaf 6)"
ANSI_white="$(tput setaf 7)"
ANSI_error="${ANSI_bold}${ANSI_red}"
ANSI_reset="$(tput sgr0)"

# Function to print with ANSI colour
function print_color { # $1=ANSI_color $2=text
	echo "$1$2$ANSI_reset"
}

# Function to print any error to stderr
function print_error {	# $1=theerror $2=printusage $3=exitcode
	echo "" >&2
	print_color $ANSI_error "ERROR: $1" >&2
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
content_data=""
stretchable_insets=0
stretchable_rect=0
stretchable_data=""
verbose=0

# Parse the options
while getopts ":c:C:hi:o:s:S:v" opt; do
	case $opt in
	c)
		content_insets=1
		content_data="$OPTARG"
		;;
	C)
		content_rect=1
		content_data="$OPTARG"
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
		stretchable_data="$OPTARG"
		;;
	S)
		stretchable_rect=1
		stretchable_data="$OPTARG"
		;;
	v)
		verbose=1
		echo; print_color $ANSI_cyan "Verbose mode ${ANSI_green}on${ANSI_cyan}."; echo
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

# Check for any usage errors
if [ -n "$error" ]; then
	print_error "$error" 1 1
fi

# Make sure the input image file exists
if [ ! -f $INPUT_FILE ]; then print_error "Cannot find the input image: $INPUT_FILE" 0 1; fi

# Set defaults...

# If no content area was specified, copy the stretchable area
if [ $content_insets -eq 0 ] && [ $content_rect -eq 0 ]; then
	if [ $verbose -ne 0 ]; then print_color $ANSI_cyan "Setting ${ANSI_magenta}content-area${ANSI_cyan} equal to ${ANSI_magenta}stretchable-area${ANSI_cyan}."; fi
	(( content_insets = stretchable_insets ))
	(( content_rect = stretchable_rect ))
    content_data="$stretchable_data"
fi

# If no output base name was specified use the base name of the input file
if [ -n $BASE_NAME ]; then
	BASE_NAME="${INPUT_FILE%.*}"
	if [ $verbose -ne 0 ]; then print_color $ANSI_cyan "Using the input file basename: ${ANSI_blue}$BASE_NAME"; fi
fi

# Set the output file name
OUTPUT_FILE="$BASE_NAME.9.png"
if [ $verbose -ne 0 ]; then print_color $ANSI_cyan "Output file will be called: ${ANSI_blue}$OUTPUT_FILE"; fi

# We are good to go...
echo

# Get the image dimensions
input_width=`identify -format "%w" $INPUT_FILE `
if [ $? -ne 0 ]; then print_error "Couldn't get image width from input image: $INPUT_FILE" 0 1; fi
input_height=`identify -format "%h" $INPUT_FILE`
if [ $? -ne 0 ]; then print_error "Couldn't get image height from input image: $INPUT_FILE" 0 1; fi
# Calculate output dimensions
(( out_width = input_width + 2 ))
(( out_height = input_height + 2 ))
if [ $verbose -ne 0 ]; then print_color $ANSI_cyan "Input image is ${ANSI_yellow}${input_width}${ANSI_cyan}x${ANSI_yellow}${input_height}${ANSI_cyan}, output image will be ${ANSI_yellow}${out_width}${ANSI_cyan}x${ANSI_yellow}${out_height}${ANSI_cyan}."; fi

# Calculate the stretchable area
IFS='-' read -ra stretchable_values <<< "$stretchable_data"
if [ $stretchable_insets -ne 0 ]; then
	# Stretchable rect specified as insets
	(( stretchable_x = stretchable_values[3] ))
	(( stretchable_y = stretchable_values[0] ))
	(( stretchable_w = input_width - stretchable_values[1] - stretchable_values[3] ))
	(( stretchable_h = input_height - stretchable_values[0] - stretchable_values[2] ))
else
	# Stretchable rect specified as rectangle
	(( stretchable_x = stretchable_values[0] ))
	(( stretchable_y = stretchable_values[1] ))
	(( stretchable_w = stretchable_values[2] ))
	(( stretchable_h = stretchable_values[3] ))
fi

# Calculate the content area
IFS='-' read -ra content_values <<< "$content_data"
if [ $content_insets -ne 0 ]; then
	# Content rect specified as insets
	(( content_x = content_values[3] ))
	(( content_y = content_values[0] ))
	(( content_w = input_width - content_values[1] - content_values[3] ))
	(( content_h = input_height - content_values[0] - content_values[2] ))
else
	# Content rect specified as rectangle
	(( content_x = content_values[0] ))
	(( content_y = content_values[1] ))
	(( content_w = content_values[2] ))
	(( content_h = content_values[3] ))
fi

# Display the stretchable and content area rectnagles
if [ $verbose -ne 0 ]; then
	print_color $ANSI_cyan "Rectangle for ${ANSI_magenta}stretchable-area${ANSI_cyan}: (${ANSI_yellow}$stretchable_x${ANSI_cyan}, ${ANSI_yellow}$stretchable_y${ANSI_cyan}, ${ANSI_yellow}$stretchable_w${ANSI_cyan}, ${ANSI_yellow}$stretchable_h${ANSI_cyan}) in input image."
	print_color $ANSI_cyan "Rectangle for ${ANSI_magenta}    content-area${ANSI_cyan}: (${ANSI_yellow}$content_x${ANSI_cyan}, ${ANSI_yellow}$content_y${ANSI_cyan}, ${ANSI_yellow}$content_w${ANSI_cyan}, ${ANSI_yellow}$content_h${ANSI_cyan}) in input image."
fi

# Generate output image
echo "Generating 9-patch PNG image..."
(( out_r = out_width - 1 ))			# Last pixel on the right of output image
(( out_b = out_height - 1 ))		# Last pixel on the bottom of output image
(( str_l = stretchable_x + 1 ))		# Left pixel of stretchable-area on output image (corrected x for 1-pixel border)
(( str_t = stretchable_y + 1 ))		# Top pixel of stretchable-area on output image (corrected y for 1-pixel border)
(( str_r = str_l + stretchable_w - 1 ))
(( str_b = str_t + stretchable_h - 1 ))
(( con_l = content_x + 1 ))			# Left pixel of content-area on output image (corrected x for 1-pixel border)
(( con_t = content_y + 1 ))			# Top pixel of content-area on output image (corrected y for 1-pixel border)
(( con_r = con_l + content_w - 1 ))
(( con_b = con_t + content_h - 1 ))
convert -size ${out_width}x${out_height} canvas:none -fill black \
	$INPUT_FILE -geometry +1+1 -composite \
	-draw "line 0,       ${str_t} 0,       ${str_b}" \
	-draw "line ${str_l},0        ${str_r},0       " \
	-draw "line ${out_r},${con_t} ${out_r},${con_b}" \
	-draw "line ${con_l},${out_b} ${con_r},${out_b}" \
	$OUTPUT_FILE
print_color ${ANSI_blue} "$OUTPUT_FILE ${ANSI_bold}${ANSI_green}Done."

