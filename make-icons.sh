##!/bin/bash -n
##
##  Generates Apple App Icon Sets from an input image.
##
set -e

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------ SETTINGS --------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Version number of "Amplitude" – the App Icon Set Generator.
#######################################
readonly AMPLITUDE_GENERATOR_VERSION="Amplitude Icon Generator Version 1.0.0"

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#--------------------------------- CONFIG -------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

################################################################################
##### These are values meant for you to be able go in and update on your local
##### copy of the generator script. This allows for default preferences to
##### easily be set without them having to be passed in as option flags every
##### time the script is run.
################################################################################

#######################################
# Whether verbose logging is enabled.
#
# Set to either "true" or "false".
#
# Made `readonly` after the input options have been read in and configured.
#######################################
VERBOSE_LOGGING_ENABLED="false"

#######################################
# Custom base for the generated icon names.
#
# E.g. If the base were "Noodle", the generated icon files would look like:
# "Noodle-60x60px.png", "Noodle-512x512px.png"...
#######################################
readonly CUSTOM_ICON_NAME_BASE=""

#######################################
# Custom Hex Color Code to use by default when padding icons.
#######################################
readonly CUSTOM_ICON_PADDING_HEX_COLOR=""

#######################################
# Custom value to use for the `author` key in the `Contents.json` metadata.
#
# You may want to set this value to your bundle ID. For additional info, see:
# https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html
#######################################
readonly CUSTOM_ICON_SET_AUTHOR_NAME=""

#######################################
# Whether or not the Icon Generator script should automatically open a window
# with the newly created Icon Set folder after it is first generated.
#
# Set to either "true" or "false".
#######################################
readonly AUTO_OPEN_NEW_ICON_SET_FOLDER="true"

#######################################
# Whether or not any existing directory with the same path should always be
# overwritten/deleted without requiring user confirmation.
#
# Set to either "true" or "false".
#######################################
readonly ALWAYS_OVERWRITE_EXISTING_OUTPUT_DIRECTORY="false"

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#----------------------------ICON SET TYPE FLAGS ------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

################################################################################
##### These flags are passed in via the command line to indicate the desired
##### type of Icon Set to be generated.
#####
##### NOTE: This generator does not support tvOS (at least currently) because
##### their icons require a unique layering format and do not use the typical
##### Apple icon sets.
################################################################################

#######################################
# Name of the option flag indicating an Icon Set configured for an iOS
# Application.
#######################################
readonly IOS_APP_ICON_SET_FLAG="IOS"

#######################################
# Name of the option flag indicating an Icon Set configured for an iOS iMessage
# Sticker Pack.
#######################################
readonly IOS_STICKERS_ICON_SET_FLAG="STICKER"

#######################################
# Name of the option flag indicating an Icon Set configured for a WatchOS
# Application.
#######################################
readonly WATCH_OS_APP_ICON_SET_FLAG="WATCH"

#######################################
# Name of the option flag indicating an Icon Set configured for a MacOS
# Application.
#######################################
readonly MAC_OS_APP_ICON_SET_FLAG="MAC"

#######################################
# Array of the supported Icon Set Type flags.
#######################################
readonly SUPPORTED_ICON_SET_FLAGS=(
  "${IOS_APP_ICON_SET_FLAG}",
  "${IOS_STICKERS_ICON_SET_FLAG}",
  "${WATCH_OS_APP_ICON_SET_FLAG}",
  "${MAC_OS_APP_ICON_SET_FLAG}"
)

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#----------------------------OPTION FLAGS -------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Name of the option flag indicating that any existing Icon Set directory with
# the same name should be overwritten/deleted..
#######################################
readonly WHITELIST_OUTPUT_OVERWRITES_FLAG="--whitelist-output-overwrites"

#######################################
# Name of the option flag indicating that any input images that are missized
# (i.e. not the expected 1024px by 1024px) should automatically be resampled to
# fit, without being prompted for approval.
#
# If this flag is not passed in, input images that are not 1024px by 1024px are
# treated as an error and require user confirmation before proceeding to resize.
#######################################
readonly WHITELIST_RESIZING_FLAG="--whitelist-icon-resizing"

#######################################
# Name of the option flag indicating that any input images that are missized
# (i.e. not the expected 1024px by 1024px) should automatically be padded with
# empty pixels to fit, without being prompted for approval.
#######################################
readonly WHITELIST_PADDING_FLAG="--whitelist-icon-padding"

#######################################
# Name of the option flag indicating that any input images that are missized
# (i.e. not the expected 1024px by 1024px) should automatically be cropped to
# fit, without being prompted for approval.
#######################################
readonly WHITELIST_CROPPING_FLAG="--whitelist-icon-cropping"

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#-------------------------------- CONSTANTS -----------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Name of the asset catalog's JSON file describing its contents.
#
# As described in:
# https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html
#######################################
readonly CONTENTS_JSON_FILENAME="Contents.json"

#######################################
# The version number of the Icon Set's Asset Catalog format – use '1'.
#######################################
readonly ICON_SET_FORMAT_VERSION="\"1\""

#######################################
# The `author` of the asset catalog (will be written into the metadata).
#######################################
readonly ICON_SET_GENERATOR_NAME="icon-a-go-go"

#######################################
# Temporary name used for the base image from which to generate the icons.
#
# The image stored at this path is deleted in cleanup.
#######################################
readonly BASE_IMAGE_FILE_NAME="FullSizeIconImage.png"

#######################################
# Expected width and height, in pixels, for the input image to make icons from.
#######################################
readonly EXPECTED_INPUT_IMAGE_PIXELS="1024"

#######################################
# Default base for generated icon names, can be overridden by a custom value.
#######################################
readonly DEFAULT_ICON_NAME_BASE="Icon"

#######################################
# Default base output Icon Sets, when not overridden by a custom value.
#######################################
readonly DEFAULT_ICON_SET_NAME_BASE="IconSet"

#######################################
# "1x" icon image scale.
#######################################
readonly SCALE_1X="1"

#######################################
# "2x" icon image scale.
#######################################
readonly SCALE_2X="2"

#######################################
# "3x" icon image scale.
#######################################
readonly SCALE_3X="3"

#######################################
# The current directory the script is executing in, in which to create the Icon
# Set.
#######################################
readonly OUTPUT_PARENT_DIR=$(pwd)

#######################################
# The value to use for the `author` key in the `Contents.json` metadata.
#
# Defaults to the name of this Icon Generator unless a custom config override
# value has been provided.
#
# Made `readonly` right after initial configuration.
#######################################
ICON_SET_AUTHOR_NAME="${ICON_SET_GENERATOR_NAME}"

#######################################
# The base name to use when creating new icons.
#
# Defaults to `DEFAULT_ICON_NAME_BASE` ("Icon"), can optionally be passed in.
#######################################
OUTPUT_ICON_IMAGE_NAME_BASE="${DEFAULT_ICON_NAME_BASE}"

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#-------------------------------- GLOBAL VARIABLES ----------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# [REQUIRED] The file name of the input image to make the icons from.
#
# Made `readonly` after the input options have been read in and configured.
#######################################
INPUT_IMAGE_FILE_NAME=""

#######################################
# String of additional flags passed in to getopts, containing the longer, more
# descriptive custom flags detailed above.
#######################################
EXTRA_FLAGS_STRING=""

#######################################
# Array of the Icon Sets to output, parsed from the user provided input. Each
# name has been validated as being prepended with a string indicating the type
# of the Icon Set to generate.
#######################################
ICON_SETS_TO_OUTPUT=()

#######################################
# [MUTATING] The name of the currently-being-generated output App Icon Set
# directory. May have multiple values over time if more than one App Icon Set
# was requested.
#######################################
CURRENT_OUTPUT_ICON_SET_DIR=""

#######################################
# [MUTATING] The type of the currently-being-generated output App Icon Set.
# One of the Icon Set Type Flags defined above (e.g "IOS", "MACOS").
#
# May have multiple values over time if more than one Icon Set was requested.
#######################################
ACTIVE_ICON_SET_TYPE=""

#######################################
# [MUTATING] The slightly more human-readable version of the Icon Set type
# currently-being-generated output App Icon Set (e.g. "iOS Sticker Pack" or
# "WatchOS App").
#
# May have multiple values over time if more than one Icon Set was requested.
#######################################
DISPLAY_ICON_SET_TYPE=""

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------ HELPER METHODS --------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Prints the usage instructions for this script and terminates the execution.
#
# Arguments:
#   - Optional error line number.
#   - Optional error message to be written to STDERR.
#######################################
function print_usage_and_exit() {
  local optional_error_line_number="${1}"
  local optional_error_message="${2}"
  if [[ -n "${optional_error_line_number}" ]]; then
    err "${optional_error_line_number}" "${optional_error_message}"
  fi

  print_usage >&2

  exit 1
}

#######################################
# Prints the usage instructions for this script.
#
# Arguments:
#   None.
#######################################
function print_usage() {
  echo ""
  echo "Usage:"
  echo "make-icons.sh [--version] [--help] "
  echo "              [--input <path-to-input-image>]"
  echo "              [--output-custom <IOS|STICKER|WATCH|MAC> <output-name>]"
  echo "              [--output-default <IOS|STICKER|WATCH|MAC>]"
  echo ""
  echo "e.g.:"
  echo ""
  echo "\`make-icons.sh --input MyIcon.png \\"
  echo "  --output-default IOS"
  echo "  --output-default STICKER"
  echo "  --output-custom WATCH MyCustomNamedWatchIcons\`"
  echo ""
  echo "  => Will use './MyIcon.png' to generate:"
  echo "     - './AppIconSet.appiconset'"
  echo "     - './StickerPackIconSet.appiconset'"
  echo "     - './MyCustomNamedWatchIcons.appiconset'"
  echo ""
}

#######################################
# Prints the help instructions for this script and terminates the execution.
#
# Arguments:
#   - Optional error message to be written to STDERR.
#######################################
function print_help_and_exit() {
  echo "Amplitude Icon Set Generator"
  echo "This tool is used to generate Apple Icon Sets from an input image."
  echo ""
  echo "Supported Icon Set Types:"
  echo " - iOS Application Icons,"
  echo " - iMessage Sticker Pack Icons,"
  echo " - WatchOS Application Icons,"
  echo " - MacOS Application Icons."

  print_usage

  echo "#######################################################################"
  echo "######################### REQUIRED PARAMETERS #########################"
  echo "#######################################################################"
  echo ""
  echo "======================> 1 (ONE) INPUT IMAGE FLAG <====================="
  echo ""
  echo " [--input|-i]: "
  echo "    '--input <path/to/my/image.png>'"
  echo ""
  echo "    The input image to transform into the output Icon Set."
  echo ""
  echo "    Preferrably a 1024px by 1024px image for best results."
  echo ""
  echo "=============> 1+ (ONE OR MORE) OUTPUT ICON SET FLAG(S) <=============="
  echo ""
  echo " [--output-default|-od] | [--output-custom|-oc]:"
  echo "    '--output-default <IOS|STICKER|WATCH|MAC>'"
  echo "    '--output-custom <IOS|STICKER|WATCH|MAC> <MyCustomOutputName>'"
  echo ""
  echo "    The type of the desired output Icon Set to output."
  echo ""
  echo "    Will generate an Icon Set of the specified type using either the"
  echo "    default output name (\`output-default\`) or with the custom output "
  echo "    name from the second argument (\`output-custom\`)."
  echo ""
  echo "    With custom names, the appropriate extensions will be added for "
  echo "    you – '.appiconset' or '.stickericonset' – the name passed in "
  echo "    should NOT have an extension."
  echo ""
  echo "    The output flags are repeatable -- more than one output Icon Set"
  echo "    type can be requested."
  echo ""
  echo "#######################################################################"
  echo "################## OPTIONAL CUSTOMIZATION PARAMATERS ##################"
  echo "#######################################################################"
  echo ""
  echo " [--icon-name-base|-n]:"
  echo "    '--icon-name-base <MyIconName>'"
  echo ""
  echo "    The base name to use for the output resized icon images."
  echo ""
  echo " [--author|-a]:"
  echo "    '--author <com.MyApp.Bundle.ID>'"
  echo ""
  echo "    The custom name to use in the Icon Set metadata for the author."
  echo ""
  echo "#######################################################################"
  echo "############################ OVERRIDE FLAGS ###########################"
  echo "#######################################################################"
  echo ""
  echo "[--${WHITELIST_OUTPUT_OVERWRITES_FLAG}|-d]: "
  echo "    Optional flag to whitelist overriding (i.e. removing) any existing "
  echo "    directories conflicting with the desired output name."
  echo ""
  echo "[--${WHITELIST_RESIZING_FLAG}|-r]"
  echo "[--${WHITELIST_PADDING_FLAG}|-p]"
  echo "[--${WHITELIST_CROPPING_FLAG}|-c]: "
  echo "    Optional flags to whitelist resizing, padding, or cropping the "
  echo "    input image to the expected 1024px by 1024px. Only ONE may be used."
  echo ""
  echo "#######################################################################"
  echo "############################# OTHER FLAGS #############################"
  echo "#######################################################################"
  echo ""
  echo "[--verbose-logging|-l]:"
  echo "    Optional flag to enable verbose logging."
  echo ""
  echo "[--version|-v]:"
  echo "    Prints the curent version."
  echo ""
  echo "[--help|-h]:"
  echo "    Prints usage help."
  echo ""
  exit 1
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#---------------------------- INPUT IMAGE RESIZING ----------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Helper that returns the width in pixels for a given image file.
#
# Arguments:
#   - The file name of the image (in the current directory) in question.
#
# Returns:
#   - The width of the image at the given file name, in pixels, parsed from the
#     `sips` return value.
#######################################
function get_image_width() {
  if [[ -z "${1}" ]]; then
    err $LINENO "get_image_width called with empty file name parameter."
    exit 1
  fi

  local filename="${1}"
  echo $(sips -g pixelWidth "${filename}" | awk '/pixelWidth/ {print $2}')
}

#######################################
# Helper that returns the height in pixels for a given image file.
#
# Arguments:
#   - The file name of the image (in the current directory) in question.
#
# Returns:
#   - The height of the image at the given file name, in pixels, parsed from the
#     `sips` return value.
#######################################
function get_image_height() {
  if [[ -z "${1}" ]]; then
    err $LINENO "get_image_height called with empty file name parameter."
    exit 1
  fi

  local filename="${1}"
  echo $(sips -g pixelHeight "${filename}" | awk '/pixelHeight/ {print $2}')
}

#######################################
# Helps enforce the input image size requirement (of 1024px by 1024px). If the
# image is another size, the user will be given the option to resize the
# current input if they do not wish to abort.
#
# This function presumes that the input image has already been copied to
# `BASE_IMAGE_FILE_NAME` in `CURRENT_OUTPUT_ICON_SET_DIR` and that is also
# the current directory.
#
# Arguments:
#   None.
#######################################
function verify_input_image_dimensions() {
  # => Verify the output directory was created before this function was called.
  local expected_dir="${OUTPUT_PARENT_DIR}/${CURRENT_OUTPUT_ICON_SET_DIR}"
  if [[ "${expected_dir}" != "$(pwd)" ]]; then
    err $LINENO "Invalid dir. Expected: ${expected_current_dir}, got: $(pwd)."
    exit 1
  fi

  # => Verify the input image was copied into the output directory for resizing.
  if [[ ! -f "${BASE_IMAGE_FILE_NAME}" ]]; then
    err $LINENO "Missing file at image path: '$(pwd)/${BASE_IMAGE_FILE_NAME}'."
    exit 1
  fi

  # => Check if the input image needs to be resized.
  #
  # Must have separate lines for declaration and assignment when using local
  # variables with command substitutious, as the `local` builtin does not
  # propagate the exit code.
  local image_width
  local image_height
  image_width=$(get_image_width "${BASE_IMAGE_FILE_NAME}")
  image_height=$(get_image_height "${BASE_IMAGE_FILE_NAME}")

  if (( "${image_width}" == "${EXPECTED_INPUT_IMAGE_PIXELS}" && \
        "${image_height}" == "${EXPECTED_INPUT_IMAGE_PIXELS}" )); then
    log "Confirmed the input image has expected dimensions."
    return
  fi

  if (( "${image_width}" == "${image_height}" && \
        "${image_width}" > "${EXPECTED_INPUT_IMAGE_PIXELS}" )); then
    log "Downsizing input image to 1024px x 1024px."
    sips --resampleHeightWidth "${EXPECTED_INPUT_IMAGE_PIXELS}" \
    "${EXPECTED_INPUT_IMAGE_PIXELS}" "${BASE_IMAGE_FILE_NAME}" >> /dev/null
    return
  fi

  # Check whether the user already passed in an input flag with their selection.
  if [[ "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_RESIZING_FLAG}"* ]]; then
    resample_input_image_to_1024_by_1024
    return
  elif [[ "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_PADDING_FLAG}"* ]]; then
    pad_input_image_to_1024_by_1024
    return
  elif [[ "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_CROPPING_FLAG}"* ]]; then
    crop_and_size_input_image_to_1024_by_1024
    return
  fi

  err $LINENO "Input image has unexpected dimensions.\n" \
  "(Expected 1024px x 1024px, got ${image_width}px x ${image_height}px.)"

  # User needs to decide whether to resize and proceed or exit.
  echo "To make icons, the input needs to be resized to 1024x1024px, either:"
  echo "- Resampling (may stretch / shrink / change the original aspect ratio)."
  echo "- Adding padding (adding 'empty' pixels to the edges to pad it out)."
  echo "- Crop and resize (cut down into a square first - better for big pics)."
  echo ""
  echo "NOTE: The original file will never be modified."
  echo ""
  echo "How do you wish to proceed?"
  echo ""
  echo "Input [1-4]:"
  select option in "Resampling" "Padding" "Cropping" "Quit"; do
    case $option in

      "Resampling")
        logn "💡TIP: Pass '--${WHITELIST_RESIZING_FLAG}' to skip this prompt."
        resample_input_image_to_1024_by_1024
        break
        ;;

      "Padding")
        logn "💡TIP: Pass '--${WHITELIST_PADDING_FLAG}' to skip this prompt."
        pad_input_image_to_1024_by_1024
        break
        ;;

      "Cropping")
        logn "💡TIP: Pass '--${WHITELIST_CROPPING_FLAG}' to skip this prompt."
        crop_and_size_input_image_to_1024_by_1024
        break
        ;;

      "Quit")
        clean_up_and_exit
        ;;
    esac
  done
}

#######################################
# Helper method that resizes the input image at `BASE_IMAGE_FILE_NAME` to the
# expected 1024px by 1024px size by resampling the image.
#
# NOTE: Resampling will alter the image aspect ratio if needed (i.e. stretch or
# squish the image).
#
# Arguments:
#   None.
#######################################
function resample_input_image_to_1024_by_1024() {
  # Stretch/squish the image to become 1024px by 1024px.
  #
  # Perform this operation on `BASE_IMAGE_FILE_NAME` in place, as that file is
  # already a temporary copy, and it needs to be 1024x1024.
  sips --resampleHeightWidth "${EXPECTED_INPUT_IMAGE_PIXELS}" \
  "${EXPECTED_INPUT_IMAGE_PIXELS}" "${BASE_IMAGE_FILE_NAME}" >> /dev/null
}

#######################################
# Helper method that resizes the input image at `BASE_IMAGE_FILE_NAME` to the
# expected 1024px by 1024px size by adding black padding as needed.
#
# Arguments:
#   None.
#######################################
function pad_input_image_to_1024_by_1024() {
  logn "Padding the input image with pixels to fit the required size..."
  # Before adding padding to the input image, make sure both dimensions are
  # under 1024x1024 (this won't affect aspect ratio).
  #
  # If the input image were, say, 2048px by 1024px, it will still need to be
  # padded (to become a square), but first must be shrunk to 1024px by 512px.
  #
  # Perform this operation on `BASE_IMAGE_FILE_NAME` in place, as that file is
  # already a temporary copy, and it needs to be 1024x1024.
  sips --resampleHeightWidthMax \
"${EXPECTED_INPUT_IMAGE_PIXELS}" "${BASE_IMAGE_FILE_NAME}" >> /dev/null

  local hex_color_code="${CUSTOM_ICON_PADDING_HEX_COLOR}"
  if [[ -z "${hex_color_code}" ]]; then
    echo "You may provide a hex color code to use to pad the icons."
    echo "For example:"
    echo "- White=#FFFFFF"
    echo "- Red=#FF0000"
    echo "- Green=#00FF00"
    echo "- Blue=#0000FF"
    echo "- Grey=#999999"
    echo ""
    read -p 'Input a color code (default is black): ' hex_color_code
  fi
  hex_color_code="${hex_color_code:-000000}" # Set fallback value to black.

  # Add padding to make the image 1024px by 1024px using the (optional)
  # customizable hex color `CUSTOM_ICON_PADDING_HEX_COLOR`.
  sips --padToHeightWidth \
  "${EXPECTED_INPUT_IMAGE_PIXELS}" "${EXPECTED_INPUT_IMAGE_PIXELS}" \
  --padColor "${hex_color_code}" "${BASE_IMAGE_FILE_NAME}" >> /dev/null
}

#######################################
# Helper method that resizes the input image at `BASE_IMAGE_FILE_NAME` to the
# expected 1024px by 1024px size by adding black padding as needed.
#
# Arguments:
#   None.
#######################################
function crop_and_size_input_image_to_1024_by_1024() {
  local image_width
  local image_height
  image_width=$(get_image_width "${BASE_IMAGE_FILE_NAME}")
  image_height=$(get_image_height "${BASE_IMAGE_FILE_NAME}")

  logn "Cropping the input image to a square shape before resizing to 1024px..."

  if (( $image_width > $image_height )); then
    # Need to trim the larger width down to match the shorter height.
    sips --cropToHeightWidth "${image_height}" "${image_height}" \
    "${BASE_IMAGE_FILE_NAME}" >> /dev/null
  else
    # Need to crop the taller height to align with the smaller width.
    sips --cropToHeightWidth "${image_width}" "${image_width}" \
    "${BASE_IMAGE_FILE_NAME}" >> /dev/null
  fi

  sips --resampleHeightWidth \
  "${EXPECTED_INPUT_IMAGE_PIXELS}" "${EXPECTED_INPUT_IMAGE_PIXELS}" \
  "${BASE_IMAGE_FILE_NAME}" >> /dev/null
  }

#######################################
# Helper function that cleans up the created `CURRENT_OUTPUT_ICON_SET_DIR`
# when the execution is interrupted before successful completion. Exits with an
# error.
#######################################
function clean_up_and_exit() {
  echo ""
  echo "Shutting down the Icon Set generator..."
  echo "Removing incomplete Icon Set directory, ${CURRENT_OUTPUT_ICON_SET_DIR}."

  cd "${OUTPUT_PARENT_DIR}"
  rm -r "${OUTPUT_PARENT_DIR}/${CURRENT_OUTPUT_ICON_SET_DIR}"
  echo "'${CURRENT_OUTPUT_ICON_SET_DIR}' has been deleted."
  exit 1
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#----------------------------- ICON IMAGE RESIZING ----------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Makes a new square copy of `BaseIconImage.png.`
#
# Arguments:
#   - One value representing the width/height of the icon to create, in pixels.
#
# Returns:
#   - Newly created file name.
#
# Example Usage:
#   `local new_square_img_filename=$(make_square_icon 40)`
#    │
#    └──> Creates a new icon that is 40px wide and 40px high.
#######################################
function make_square_icon() {
  local new_size_in_px="${1}"

  local new_image_name
  new_image_name=$(make_icon_name $new_size_in_px $new_size_in_px)

  if [[ ! -f "${new_image_name}" ]]; then
    # Avoid making duplicates of files that already exist to take less memory.
    # A new image doesn't actually need to be resized if there's already an
    # identical one that already exists. Only call sips if there's no file with
    # the same name in the directory.
    #
    # (Redirect output to /dev/null to avoid returning it as output.)
    sips --resampleHeightWidth "${new_size_in_px}" "${new_size_in_px}" \
    --out "${new_image_name}" "${BASE_IMAGE_FILE_NAME}" >> /dev/null
  fi

  # Return the new image name.
  echo "${new_image_name}"
}

#######################################
# Makes a new cropped non-square/oblong copy of `BaseIconImage.png` where
# `new_width` > `new_height`.
#
# The base image is resized down to a square of the given width before cropping
# off the top and bottom down to the given height.
#
# Arguments:
#   - The new width (in pixels) of the image to create.
#   - The new height (in pixels) of the image to create.
#
# Returns:
#   - Newly created file name, which is based off the given icon size.
#
# Example Usage:
#   `local new_cropped_img_filename=$(make_cropped_icon 120 80)`
#    │
#    └──> Creates a new icon that is 120px wide and 80px high.
#######################################
function make_cropped_icon() {
  local new_width_in_px="${1}"
  local new_height_in_px="${2}"

  if (( new_height_in_px > new_width_in_px )); then
    # This error would become a valid use case if Apple introduced new icons
    # with that ratio, but this method currently assumes that is not true and
    # would need to have that functionality added to support the new sizes.
    err $LINENO "`make_cropped_icon` called with `height` greater than `width`."
    exit 1
  fi

  local new_image_name
  new_image_name=$(make_icon_name $new_width_in_px $new_height_in_px)

  # Avoid making duplicates of the same image if they already exist.
  if [[ ! -f "${new_image_name}" ]]; then
    # Make a new icon image of size: $new_width_in_px x $new_height_in_px.
    #
    # Redirects `sips` output to /dev/null to keep it from being returned.

    # 1. First, downsize to $new_width_in_px x $new_width_in_px (because the new
    #    width will always be greater than height here).
    sips --resampleHeightWidth "${new_width_in_px}" "${new_width_in_px}" \
    --out "${new_image_name}" $BASE_IMAGE_FILE_NAME >> /dev/null

    # 2. Crop the excess height.
    sips --cropToHeightWidth "${new_height_in_px}" "${new_width_in_px}" \
    "${new_image_name}" >> /dev/null
  fi

  # 3. Return the new image name.
  echo "${new_image_name}"
}

#######################################
# Helper function that creates the formatted name for an icon file based on its
# height and width in pixels.
#
# Main purpose is to consolidate the naming to only one spot to avoid
# inconsistencies.
#
# Arguments:
#   - The width of the given icon, in pixels.
#   - The height of the given icon, in pixels.
#
# Returns:
#   - A string with the created file name.
#
# Example Usage:
#   `make_icon_file_name_with_width_and_height 100 80`
#    │
#    └──> Returns the string: "Icon-100x80.png"
#######################################
function make_icon_name() {
  local icon_width_in_px="${1}"
  local icon_height_in_px="${2}"

  if (( icon_height_in_px > icon_width_in_px )); then
    # Make sure they are being passed in in the right order.
    err $LINENO "`make_icon_name` called with `height` greater than `width`."
    exit 1
  fi

  # NOTE: Only the sizes are included in these names and not any of the other
  # icon-specific qualifiers (like 'idiom' or 'scale') to allow images of the
  # same size to be shared across use cases.
  local icon_dimensions="${icon_width_in_px}x${icon_height_in_px}px"
  local new_icon_name="${OUTPUT_ICON_IMAGE_NAME_BASE}-${icon_dimensions}.png"
  echo "${new_icon_name}"
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------- JSON FORMATTING ------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Appends the corresponding JSON data for the provided icon info to
# `Contents.json` (either with or without a trailing comma, depending on the
# input).
#
# Arguments:
#   The following arguments should be passed exactly as they are expected to
#   appear in the `Contents.json` file. For additional information on these
#   parameters and the lists of permitted values, see:
#   https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html
#
#   - `icon_filename`:  Image filename in the icon set to add to the `Contents`.
#   - `icon_idiom`:     Idiom (device type) of the icon (e.g. "ipad").
#   - `icon_scale`:     Scale of the icon (e.g. "3" – just the number).
#   - `icon_platform`:  [Optional] A string with the platform of the icon, if
#                       the icon is limited to a certain platform (e.g. "ios").
#   - `icon_subtype`:   [Optional] For Apple Watch icons, typically, to indicate
#                       which watch they are sized for.
#   - `icon_role`:      [Optional] For Apple Watch icons, again, typically to
#                       specify a specicial use case (or role) for the icon.
#
# Example Usage:
#   `add_icon_to_json my-icon.png "ipad" "3"`
#######################################
function add_icon_to_json() {
  local icon_filename="${1}"
  local icon_idiom="${2}"
  local icon_scale="${3}"
  local icon_platform="${4}"
  local icon_subtype="${5}"
  local icon_role="${6}"

  local icon_width_px
  local icon_height_px
  icon_width_px=$(get_image_width "${icon_filename}")
  icon_height_px=$(get_image_height "${icon_filename}")

  # The icon size needs to have decimals as one of the iPad's icons has half-pt.
  local icon_width_pts=$(awk "BEGIN {print ${icon_width_px}/${icon_scale}}")
  local icon_height_pts=$(awk "BEGIN {print ${icon_height_px}/${icon_scale}}")
  local icon_size="${icon_width_pts}x${icon_height_pts}"

  # => Write out the provided values to the Icon Set's `Contents.json`.

  echo "    {"                                        >> $CONTENTS_JSON_FILENAME
  echo "      \"filename\" : \"${icon_filename}\","   >> $CONTENTS_JSON_FILENAME
  echo "      \"idiom\" : \"${icon_idiom}\","         >> $CONTENTS_JSON_FILENAME
  echo "      \"scale\" : \"${icon_scale}x\","        >> $CONTENTS_JSON_FILENAME

  if [[ -n "${icon_platform}" ]]; then
    echo "      \"platform\" : \"${icon_platform}\"," >> $CONTENTS_JSON_FILENAME
  fi

  if [[ -n "${icon_subtype}" ]]; then
    echo "      \"subtype\" : \"${icon_subtype}\","   >> $CONTENTS_JSON_FILENAME
  fi

  if [[ -n "${icon_role}" ]]; then
    echo "      \"role\" : \"${icon_role}\","         >> $CONTENTS_JSON_FILENAME
  fi

  echo "      \"size\" : \"${icon_size}\""            >> $CONTENTS_JSON_FILENAME

  echo "    },"                                       >> $CONTENTS_JSON_FILENAME
}

#######################################
# Helper that writes the first few opening brackets to the `Contents.JSON` file.
#
# Arguments:
#   None.
#######################################
function start_current_contents_json_file() {
  # => Create the `Contents.json` file for the App Icon Set.
  log "--> Creating 'Contents.json' in ${CURRENT_OUTPUT_ICON_SET_DIR}..."
  touch $CONTENTS_JSON_FILENAME

  # => Start off the beginning of the `Contents` JSON file.
  echo "{"                >> $CONTENTS_JSON_FILENAME
  echo "  \"images\" : [" >> $CONTENTS_JSON_FILENAME
}

#######################################
# Helper that writes the adds metadata to the `Contents` JSON file and closes
# the remaining open brackets, completining the file contents.
#
# Arguments:
#   None.
#######################################
function add_metadata_and_finish_contents_json_file() {
  ##############################################################################
  ######## NOTE: The final image created always adds an extra trailing comma,
  ######## which must be removed for valid JSON syntax.
  ##############################################################################

  # Truncate the last TWO characters – first the newline, then the extra comma.
  truncate -s-2 $CONTENTS_JSON_FILENAME

  # Re-add the removed newline.
  echo "" >> $CONTENTS_JSON_FILENAME

  # Add the metadata `info` to `Contents.json` before the closing brackets.
  log "Finishing up 'Contents.json' metadata..."

  # Close the array of icon images.
  echo "  ],"                                          >> $CONTENTS_JSON_FILENAME

  # Add the `Contents` file metadata.
  echo "  \"info\" : {"                                >> $CONTENTS_JSON_FILENAME

  # -> Add the 'author' of the given asset catalog.
  echo "    \"author\" : \"${ICON_SET_AUTHOR_NAME}\"," >> $CONTENTS_JSON_FILENAME

  # -> Add the asset catalog format version used ('1').
  echo "    \"version\" : ${ICON_SET_FORMAT_VERSION}" >> $CONTENTS_JSON_FILENAME

  # Close the remaining open brackets to complete writing `Contents.json` file.
  echo "  }"                                           >> $CONTENTS_JSON_FILENAME
  echo "}"                                             >> $CONTENTS_JSON_FILENAME
  echo ""                                              >> $CONTENTS_JSON_FILENAME
}

#######################################
# Returns the extension needed to create an Icon Set for the given Icon Set Type
# from `SUPPORTED_ICON_SET_FLAGS`.
#
# Arguments:
#   - The value from `SUPPORTED_ICON_SET_FLAGS` that represents the desired Icon
#     Set type to use to pick the extension.
#######################################
function get_icon_set_extension() {
  local icon_set_type="${1}"

  local app_icon_extension="appiconset"
  local stickers_icon_extension="stickersiconset"

  case "${icon_set_type}" in
    "${IOS_APP_ICON_SET_FLAG}") echo "${app_icon_extension}" ;;
    "${IOS_STICKERS_ICON_SET_FLAG}") echo "${stickers_icon_extension}" ;;
    "${WATCH_OS_APP_ICON_SET_FLAG}") echo "${app_icon_extension}" ;;
    "${MAC_OS_APP_ICON_SET_FLAG}") echo "${app_icon_extension}" ;;
    *)
      print_usage_and_exit $LINENO \
      "Unknown Icon Set Type: \"${icon_set_type}\"." ;;
  esac
}

#######################################
# Returns the friendly description of the Icon Set Type provided.
#
# Arguments:
#   - An Icon Set type value from `SUPPORTED_ICON_SET_FLAGS`.
#
# Returns:
#   - A string with a slightly more display-friendly version of the input value.
#      E.g. Input: "IOS" => Output: "iOS".
#######################################
function get_icon_set_type_name() {
  local icon_set_type="${1}"

  local description
  case "${icon_set_type}" in
    "${IOS_APP_ICON_SET_FLAG}") description="App" ;;
    "${IOS_STICKERS_ICON_SET_FLAG}") description="Sticker Pack" ;;
    "${WATCH_OS_APP_ICON_SET_FLAG}") description="WatchOS App" ;;
    "${MAC_OS_APP_ICON_SET_FLAG}") description="MacOS App" ;;
    *)
      print_usage_and_exit $LINENO \
      "Unknown Icon Set Type: \"${icon_set_type}\"." ;;
  esac

  echo "${description}"
}

#######################################
# Handles an input "Default-Output" parameter (with slight validation), adding
# the default output name to the Icon Sets to Output list.
#
# Arguments:
#   - An Icon Set type value from `SUPPORTED_ICON_SET_FLAGS` that was passed as
#     an argument to the `--default-output` flag.
#######################################
function handle_default_output_type_arg {
  local icon_set_type
  icon_set_type=$(validated_icon_set_type "${1}")

  local extension
  extension=$(get_icon_set_extension "${icon_set_type}")

  # Get the type description with no spaces.
  local description
  description=$(get_icon_set_type_name "${icon_set_type}" | tr -d ' ')

  local default_output="${description}${DEFAULT_ICON_SET_NAME_BASE}"

  # Get the appropriate extension to use for the input Icon Set Type .
  ICON_SETS_TO_OUTPUT+=( "${icon_set_type} ${default_output}.${extension}" )
}

#######################################
# Handles an input "Output" parameter (with slight validation), adding the
# custom output name to the Icon Sets to Output list.
#
# Arguments:
#   - An Icon Set type value from `SUPPORTED_ICON_SET_FLAGS` that was passed as
#     an argument to the `--default-output` flag.
#   - The custom output Icon Set name.
#######################################
function handle_custom_named_output_args {
  local icon_set_type
  icon_set_type=$(validated_icon_set_type "${1}")

  local custom_output_name="${2}"

  # => Do a could validation checks to make sure the input arguments are valid.
  if [[ -z "${custom_output_name}" ]]; then
    print_usage_and_exit $LINENO "Must have a non-empty output name."
  fi

  local extension
  extension=$(get_icon_set_extension "${icon_set_type}")

  local output="${icon_set_type} ${custom_output_name}.${extension}"

  # Get the appropriate extension to use for the input Icon Set Type.
  ICON_SETS_TO_OUTPUT+=( "${output}" )
}

#######################################
# Helper function to normalized and validate an input Icon Set Type.
#
# Arguments:
#   - An Icon Set type value from `SUPPORTED_ICON_SET_FLAGS` that was passed in.
#
# Returns:
#   - The uppercased, validated Icon Set type from `SUPPORTED_ICON_SET_FLAGS`.
#######################################
function validated_icon_set_type {
  # => Uppercase the input type (e.g. 'ios' => 'IOS').
  local uppercased_type
  uppercased_type=$(echo "${1}" | awk '{ print toupper($0) }')

  # => Verify the input type is not empty.
  if [[ -z "${uppercased_type}" ]]; then
    print_usage_and_exit $LINENO "Missing the Output Icon Set Type argument."
  fi

  # => Verify the input type is one of the supported types.
  if [[ ! "${SUPPORTED_ICON_SET_FLAGS[@]}" =~ "${uppercased_type}" ]]; then
    print_usage_and_exit $LINENO \
      "Invalid Output Icon Set Type: \"${uppercased_type}\"."
  fi

  # => Return the uppercased Icon Set Type.
  echo "${uppercased_type}"
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#---------------------------------- LOGGING -----------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Helper function for printing an error to STDERR.
#
# Arguments:
#   - The line number where the error was generated (`$LINENO`).
#   - Any error information that should be logged.
#######################################
function err() {
  local error_line="${1}"
  shift
  local error_message="$*"

  local red_text='\033[0;31m'
  local no_color_text='\033[0m'

  echo "" >&2
  echo "${red_text}[ERROR]:${error_line}${no_color_text} – ${error_message}" >&2
  echo "" >&2
}

#######################################
# Helper function for logging a message to STDOUT – no-op if VERBOSE_LOGGING is
# disabled.
#
# Arguments:
#   - The message that should be logged.
#######################################
function log() {
  if [[ "${VERBOSE_LOGGING_ENABLED}" == "true" ]]; then
    echo "$*"
  fi
}

#######################################
# Helper function for logging a message with added linebreaks for readability.
#######################################
function logn() {
  log ""
  log "$*"
  log ""
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#----------------------------- ICON SET HELPERS -------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Manages calling the image creation methods and the `Contents.json` creation
# with each icon size required for an iOS iMessage Sticker Pack Icon Set.
#
# Arguments:
#   - None.
#######################################
function make_ios_sticker_pack_icons() {
  logn "Generating output icons from $INPUT_IMAGE_FILE_NAME for iOS Stickers."

  log "==> Creating 29x29pt image(s) for iPhone Settings and iPad Settings..."
  # A) 58x58px
  add_icon_to_json "$(make_square_icon 58)" "iphone" $SCALE_2X
  add_icon_to_json "$(make_square_icon 58)" "ipad" $SCALE_2X
  # B) 87x87px
  add_icon_to_json "$(make_square_icon 87)" "iphone" $SCALE_3X

  log "==> Creating 60x45pt image(s) for Messages iPhone..."
  # A) 120x90px
  add_icon_to_json "$(make_cropped_icon 120 90)" "iphone" $SCALE_2X
  # B) 180x87px
  add_icon_to_json "$(make_cropped_icon 180 135)" "iphone" $SCALE_3X

  log "==> Creating 67x50pt image(s) for Messages iPad..."
  # A) 134x100px
  add_icon_to_json "$(make_cropped_icon 134 100)" "ipad" $SCALE_2X

  log "==> Creating 74x55pt image(s) for Messages iPad Pro..."
  # A) 148x110px
  add_icon_to_json "$(make_cropped_icon 148 110)" "ipad" $SCALE_2X

  log "==> Creating 1024x1024pt image(s) for App Store..."
  # A) 1024x1024px (App Store)
  add_icon_to_json "$(make_square_icon 1024)" "ios-marketing" $SCALE_1X

  log "==> Creating 1024x768pt image(s) for Messages App Store..."
  # A) 1024x768px (Messages App Store)
  add_icon_to_json "$(make_cropped_icon 1024 768)" \
  "ios-marketing" $SCALE_1X "ios"

  log "==> Creating 27x20pt image(s) for Messages..."
  # A) 54x40px
  add_icon_to_json "$(make_cropped_icon 54 40)" "universal" $SCALE_2X "ios"
  # B) 81x60px
  add_icon_to_json "$(make_cropped_icon 81 60)" "universal" $SCALE_3X "ios"

  log "==> Creating 32x24pt image(s) for Messages..."
  # A) 64x48px
  add_icon_to_json "$(make_cropped_icon 64 48)" "universal" $SCALE_2X "ios"
  # B) 96x72px
  add_icon_to_json "$(make_cropped_icon 96 72)" "universal" $SCALE_3X "ios"

  # Verify that the expected number of icons were created.
  verify_directory_contains_expected_icon_count 12
}

#######################################
# Manages calling the image creation methods and the `Contents.json` creation
# with each icon size required for an iOS Application Icon Set.
#
# Arguments:
#   - None.
#######################################
function make_ios_app_icons() {
  logn "Generating output icons from $INPUT_IMAGE_FILE_NAME for an iOS App."

  log "==> Creating 20x20pt image(s) for iPhone/iPad Notifications..."
  # A) 20x20px (iPad)
  add_icon_to_json "$(make_square_icon 20)" "ipad" $SCALE_1X
  # A) 40x40px (iPad/iPhone)
  add_icon_to_json "$(make_square_icon 40)" "iphone" $SCALE_2X
  add_icon_to_json "$(make_square_icon 40)" "ipad" $SCALE_2X
  # B) 60x60px (iPhone)
  add_icon_to_json "$(make_square_icon 60)" "iphone" $SCALE_3X

  log "==> Creating 29x29pt image(s) for iPhone/iPad Settings..."
  # B) 29x29px (iPad)
  add_icon_to_json "$(make_square_icon 29)" "ipad" $SCALE_1X
  # B) 58x58px (iPad/iPhone)
  add_icon_to_json "$(make_square_icon 58)" "iphone" $SCALE_2X
  add_icon_to_json "$(make_square_icon 58)" "ipad" $SCALE_2X
  # B) 87x87px (iPad/iPhone)
  add_icon_to_json "$(make_square_icon 87)" "iphone" $SCALE_3X

  log "==> Creating 40x40pt image(s) for iPhone/iPad Spotlight..."
  # A) 40x40px (iPad)
  add_icon_to_json "$(make_square_icon 40)" "ipad" $SCALE_1X
  # B) 80x80px (iPad/iPhone)
  add_icon_to_json "$(make_square_icon 80)" "ipad" $SCALE_2X
  add_icon_to_json "$(make_square_icon 80)" "iphone" $SCALE_2X
  # C) 120x120px (iPhone)
  add_icon_to_json "$(make_square_icon 120)" "iphone" $SCALE_3X

  log "==> Creating 60x60pt image(s) for iPhone App..."
  # A) 120x120px (iPhone)
  add_icon_to_json "$(make_square_icon 120)" "iphone" $SCALE_2X
  # B) 180x180px (iPhone)
  add_icon_to_json "$(make_square_icon 180)" "iphone" $SCALE_3X

  log "==> Creating 76x76pt image(s) for iPad App..."
  # A) 76x76px (iPad)
  add_icon_to_json "$(make_square_icon 76)" "ipad" $SCALE_1X
  # B) 152x152px (iPad)
  add_icon_to_json "$(make_square_icon 152)" "ipad" $SCALE_2X

  log "==> Creating 83.5x83.5pt image for iPad (12.9-inch) App..."
  # A) 167x167px (iPad)
  add_icon_to_json "$(make_square_icon 167)" "ipad" $SCALE_2X

  log "==> Creating 1024x1024pt image(s) for App Store..."
  # A) 1024x1024px (App Store)
  add_icon_to_json "$(make_square_icon 1024)" "ios-marketing" $SCALE_1X

  # Verify that the expected number of icons were created.
  verify_directory_contains_expected_icon_count 13
}

#######################################
# Manages calling the image creation methods and the `Contents.json` creation
# with each icon size required for an WatchOS Application Icon Set.
#
# Arguments:
#   - None.
#######################################
function make_watchos_app_icons() {
  logn "Generating output icons from $INPUT_IMAGE_FILE_NAME for an WatchOS App."

  # The Icon Set for WatchOS requires values for "role" and "subtype" on some
  # icons, so the optional parameters like "platform", "role" and "subtype" need
  # to be passed empty strings in those cases.

  log "==> Creating 24 + 27.5pt images for Apple Watch Notification Center..."
  # A) 48x48px
  add_icon_to_json "$(make_square_icon 48)" "watch" $SCALE_2X \
  "" "38mm" "notificationCenter"
  # B) 55x55px
  add_icon_to_json "$(make_square_icon 55)" "watch" $SCALE_2X \
  "" "42mm" "notificationCenter"

  log "==> Creating 29x29pt image(s) for Apple Watch Companion Settings..."
  # A) 58x58px
  add_icon_to_json "$(make_square_icon 58)" "watch" $SCALE_2X \
  "" "" "companionSettings"
  # B) 87x87px
  add_icon_to_json "$(make_square_icon 87)" "watch" $SCALE_3X \
  "" "" "companionSettings"

  log "==> Creating 40pt + 44pt + 50pt images for Apple Watch Home Screen..."
  # A) 80x80px
  add_icon_to_json "$(make_square_icon 80)" "watch" $SCALE_2X \
  "" "38mm" "appLauncher"
  # B) 88x88px
  add_icon_to_json "$(make_square_icon 88)" "watch" $SCALE_2X \
  "" "40mm" "appLauncher"
  # C) 100x100px
  add_icon_to_json "$(make_square_icon 100)" "watch" $SCALE_2X \
  "" "44mm" "appLauncher"

  log "==> Creating 86pt + 98pt + 108pt images for Apple Watch Short Look..."
  # A) 172x172px
  add_icon_to_json "$(make_square_icon 172)" "watch" $SCALE_2X \
  "" "38mm" "quickLook"
  # B) 196x196px
  add_icon_to_json "$(make_square_icon 196)" "watch" $SCALE_2X \
  "" "42mm" "quickLook"
  # C) 216x216px
  add_icon_to_json "$(make_square_icon 216)" "watch" $SCALE_2X \
  "" "44mm" "quickLook"

  log "==> Creating 1024x1024pt image for Apple Watch App Store..."
  # A) 1024x1024px (App Store)
  add_icon_to_json "$(make_square_icon 1024)" "watch-marketing" $SCALE_1X

  # Verify that the expected number of icons were created.
  verify_directory_contains_expected_icon_count 11
}

#######################################
# Manages calling the image creation methods and the `Contents.json` creation
# with each icon size required for an MacOS Application Icon Set.
#
# Arguments:
#   - None.
#######################################
function make_macos_app_icons() {
  logn "Generating output icons from $INPUT_IMAGE_FILE_NAME for an MacOS App."

  log "==> Creating 16x16pt image(s) for Mac..."
  # A) 16x16px
  add_icon_to_json "$(make_square_icon 16)" "mac" $SCALE_1X
  # B) 32x32px
  add_icon_to_json "$(make_square_icon 32)" "mac" $SCALE_2X

  log "==> Creating 32x32pt image(s) for Mac..."
  # A) 32x32px
  add_icon_to_json "$(make_square_icon 32)" "mac" $SCALE_1X
  # B) 64x64px
  add_icon_to_json "$(make_square_icon 64)" "mac" $SCALE_2X

  log "==> Creating 128x128pt image(s) for Mac..."
  # A) 128x128px
  add_icon_to_json "$(make_square_icon 128)" "mac" $SCALE_1X
  # B) 256x256px
  add_icon_to_json "$(make_square_icon 256)" "mac" $SCALE_2X

  log "==> Creating 256x256pt image(s) for Mac..."
  # A) 256x256px
  add_icon_to_json "$(make_square_icon 256)" "mac" $SCALE_1X
  # B) 512x512px
  add_icon_to_json "$(make_square_icon 512)" "mac" $SCALE_2X

  log "==> Creating 512x512pt image for Mac (including App Store)..."
  # A) 512x512px
  add_icon_to_json "$(make_square_icon 512)" "mac" $SCALE_1X
  # B) 1024x1024px
  add_icon_to_json "$(make_square_icon 1024)" "mac" $SCALE_2X

  # Verify that the expected number of icons were created.
  verify_directory_contains_expected_icon_count 7
}

#######################################
# Helper to verify the generated icon set contains the expected number of icons.
#
# Arguments:
#   - The expected number of icons.
#######################################
function verify_directory_contains_expected_icon_count() {
  local expected_count="${1}"

  # Verify that the expected number of icons were created.
  local actual_count
  actual_count=$(ls -lR ./"${OUTPUT_ICON_IMAGE_NAME_BASE}"*.png | wc -l)

  if (($actual_count != $expected_count)); then
    err $LINENO "Expected ${expected_count} icons, got ${actual_count}."
    exit 1
  fi

  log "Confirmed created Icon Set contains ${actual_icon_count} images."
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------- GENERAL DIRECTORY CREATION -------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Iterates the requested Icon Set information passed in at launch and dispatches
# the work to generate them.
#
# Arguments:
#   - None.
#######################################
function begin_generating_icon_sets_to_output() {
  local created_icon_sets=()

  # The array `ICON_SETS_TO_OUTPUT` consists of strings each with a single space
  # between their first argument (the Icon Set Type) and their second argument
  # (the Icon Set name).
  for set_to_output in "${ICON_SETS_TO_OUTPUT[@]}"; do
    # 1. Split the Output Icon Set arguments.
    ACTIVE_ICON_SET_TYPE=$(echo "${set_to_output}" | awk '{print $1;}')
    CURRENT_OUTPUT_ICON_SET_DIR=$(echo "${set_to_output}" | awk '{print $2;}')

    # Add a more display-friendly description of each of the Icon Set Types.
    DISPLAY_ICON_SET_TYPE=$(get_icon_set_type_name "${ACTIVE_ICON_SET_TYPE}")

    # 2. Create the Output Icon Set directory, `Contents.json`...
    begin_new_app_icon_set

    # 3. Create the appropriate icons, adding them to `Contents.json`.
    case "${ACTIVE_ICON_SET_TYPE}" in
      IOS) make_ios_app_icons ;;
      STICKER) make_ios_sticker_pack_icons ;;
      WATCH) make_watchos_app_icons ;;
      MAC) make_macos_app_icons ;;
      *) err $LINENO "Unknown type: \"${ACTIVE_ICON_SET_TYPE}\"." && exit 1 ;;
    esac

    # 4. Put finishing touches on the Output Icon Set directory.
    finish_completed_app_icon_set
    created_icon_sets+=("${CURRENT_OUTPUT_ICON_SET_DIR}")
  done

  echo ""
  echo "$(date +"%T") – Generated ${#created_icon_sets[@]} Icon Set(s):"
  for created_icon_set in "${created_icon_sets[@]}"; do
    echo "- ${created_icon_set}."
  done
}

#######################################
# Helper that creates a new directory for the active Output Icon Set (handling
# overwriting if requested) and handles verifying the input image is okay.
#######################################
function begin_new_app_icon_set() {
  log ""
  log "######################################################################"
  log "######################################################################"
  log "##################### => Creating New ${DISPLAY_ICON_SET_TYPE} Icon Set"
  log "######################################################################"
  log "######################################################################"
  log ""

  echo "Making ${CURRENT_OUTPUT_ICON_SET_DIR} – ${DISPLAY_ICON_SET_TYPE} Icons."

  # 1. Perform validation on the input.

  # => Verify there is not already a directory at the requested output.
  if [[ -d "${OUTPUT_PARENT_DIR}/${CURRENT_OUTPUT_ICON_SET_DIR}" ]]; then
    # If not whitelisted, require confirmation before deleting anything.
    if [[ "${EXTRA_FLAGS_STRING}" != *"${WHITELIST_OUTPUT_OVERWRITES_FLAG}"* \
       && "${ALWAYS_OVERWRITE_EXISTING_OUTPUT_DIRECTORY}" != "true" ]]; then
      err $LINENO "Directory \"${CURRENT_OUTPUT_ICON_SET_DIR}\" already exists."
      echo "Must remove existing directory to continue. Delete?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes)
            logn "💡TIP: Pass '--${WHITELIST_OUTPUT_OVERWRITES_FLAG}' " \
              "to skip this prompt."
            break
            ;;
          No)
            echo "Aborting."
            exit 1
            ;;
        esac
      done
    else
      log "Output overriding whitelisted, going to remove old output directory."
    fi

    # Delete the conflicting directory and carry on with making the new one.
    log "Deleting old ${OUTPUT_PARENT_DIR}/${CURRENT_OUTPUT_ICON_SET_DIR}."
    rm -r "${OUTPUT_PARENT_DIR}/${CURRENT_OUTPUT_ICON_SET_DIR}"
  fi

  # 2. Start making the new Icon Set.

  logn "Creating ${CURRENT_OUTPUT_ICON_SET_DIR} in ${OUTPUT_PARENT_DIR}."

  # => Make the directory for the requested App Icon Set.
  mkdir "$CURRENT_OUTPUT_ICON_SET_DIR"

  # => Temporarily make a copy of the full sized input image in the output
  #    directory so it can be be resized (if needed) and kept in an easy spot
  #    while being used to generate the icons.
  cp "${INPUT_IMAGE_FILE_NAME}" \
  "${CURRENT_OUTPUT_ICON_SET_DIR}/${BASE_IMAGE_FILE_NAME}"

  # Pop in to the Icon Set directory so it is easier to manipulate the images.
  cd "${CURRENT_OUTPUT_ICON_SET_DIR}"

  # 3. Finish by starting the input validation (may undergo duplicate runs – one
  # for each Icon Set – but it's not a bottleneck.

  # => Wait until after creating the output directory to verify the input image
  #    size, even though it means having to potentially perform clean-up to
  #    delete it on failure – the input image cannot be resized in-place, and
  #    it's not worth it to try to solve potentially name collisions in the
  #    parent directory for the resized input image.
  verify_input_image_dimensions

  # 4. Create the `Contents.json` file for the App Icon Set.
  start_current_contents_json_file
}

#######################################
# Completes the final steps to create the currently-being-generated Output Icon
# Set (finishing `Contents.json`, removing the temporary image file, etc)...
#
# Also starts the next Icon Set type to be generated when complete.
#
# Arguments:
#   - None.
#######################################
function finish_completed_app_icon_set() {
  # => Add the metadata and closing brackets to the current `Contents.json`.
  add_metadata_and_finish_contents_json_file

  # => Remove the extra temporary copy of the full size image in the Icon Set.
  rm "${BASE_IMAGE_FILE_NAME}"

  logn "🏁 Finished generating the ${DISPLAY_ICON_SET_TYPE} Icon Set. 🏁"

  # => Open the folder with the new Icon Set for the user.
  log "Disk usage of ${CURRENT_OUTPUT_ICON_SET_DIR} is approximately: ~$(du -h)"
  logn "Opening the newly created ${CURRENT_OUTPUT_ICON_SET_DIR} folder..."

  cd ..

  if [[ "${AUTO_OPEN_NEW_ICON_SET_FOLDER}" == "true" ]]; then
    open "${CURRENT_OUTPUT_ICON_SET_DIR}"
  fi
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#-------------------------- VALIDATION HELPERS --------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

#######################################
# Validates the provided argument is non-empty and is not a flag argument.
#
# Arguments:
#   - The flag whose input is being validated.
#   - The input argument to validate.
#######################################
function validate_input_argument() {
  local input_flag="${1}"
  local input_argument="${2}"

  # => Verify the argument is not empty.
  if [[ -z "${input_argument}" ]]; then
    print_usage_and_exit $LINENO \
      "Missing required argument for flag \`${input_flag}\`."
  fi

  # => Verify the "argument" is not the start of the next flag.
  if [[ ( "${input_argument}" == "-"* ) ]]; then
    print_usage_and_exit $LINENO \
      "Missing required argument for flag \`${input_flag}\`."
  fi
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------ SCRIPT BODY -----------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

####################################
# 1. Parse input options and constant values.
####################################

# => Check in case no input arguments were provided).
if [[ $# -eq 0 ]]; then
  print_help_and_exit
fi

# => Override the default value for the Asset Catalog author name if a custom
#    config value has been set – do this before the input options, as input
#    flags should override custom config.
if [[ -n "${CUSTOM_ICON_SET_AUTHOR_NAME}" ]]; then
  ICON_SET_AUTHOR_NAME="${CUSTOM_ICON_SET_AUTHOR_NAME}"
fi

# => Do the same for the Output Icon Name Base, so it can be set over by the
#    input if a flag was passed in.
if [[ -n "${CUSTOM_ICON_NAME_BASE}" ]]; then
  OUTPUT_ICON_IMAGE_NAME_BASE="${CUSTOM_ICON_NAME_BASE}"
fi

# => Parse input options.
while [[ $# -gt 0 ]]
do
  flag="${1}"
  shift # Shift past `flag`.

  case "${flag}" in

    # ===> [REQUIRED] Input Image File Name.

    -i|--input)
      validate_input_argument "${flag}" "${1}"
      INPUT_IMAGE_FILE_NAME="${1}"
      shift # Shift past file name param.
      ;;

    # ===> [REQUIRED][REPEATABLE] Output Icon Set Type & Name.

    -oc|--output-custom)
      validate_input_argument "${flag}" "${1}"
      validate_input_argument "${flag}" "${2}"
      # "Output" flag should have two arguments:
      # (1) Icon Set Type
      # (2) Icon Set Output Name.
      handle_custom_named_output_args "${1}" "${2}"
      shift 2 # Shift past Icon Set Type param and Icon Set Name param.
      ;;

    -od|--output-default)
      validate_input_argument "${flag}" "${1}"
      # "Default" Output flag, which still requires an Icon Set Type argument,
      # but will set a generic, default name for the prduced Icon Set.
      handle_default_output_type_arg "${1}"
      shift # Shift past Icon Set Type param.
      ;;

    # ===> [OPTIONAL] Custom overrides.

    -n|--icon-name-base)
      validate_input_argument "${flag}" "${1}"
      OUTPUT_ICON_IMAGE_NAME_BASE="${1}"
      shift
      ;;
    -a|--author)
      validate_input_argument "${flag}" "${1}"
      ICON_SET_AUTHOR_NAME="${1}"
      shift
      ;;

    # ===> [OPTIONAL] Configuration flags.

    -d|--whitelist-output-overwrites)
      EXTRA_FLAGS_STRING+=" ${WHITELIST_OUTPUT_OVERWRITES_FLAG}"
      ;;
    -r|--whitelist-icon-resizing)
      EXTRA_FLAGS_STRING+=" ${WHITELIST_RESIZING_FLAG}"
      ;;
    -p|--whitelist-icon-padding)
      EXTRA_FLAGS_STRING+=" ${WHITELIST_PADDING_FLAG}"
      ;;

    -c|--whitelist-icon-cropping)
      EXTRA_FLAGS_STRING+=" ${WHITELIST_CROPPING_FLAG}"
      ;;

    -l|--verbose-logging) VERBOSE_LOGGING_ENABLED="true" ;;
    -v|--version) echo "${AMPLITUDE_GENERATOR_VERSION}\n" && exit 0;;

    -h|--help) print_help_and_exit ;;
    *) print_usage_and_exit $LINENO "Unknown option: ${flag}." ;;
esac
done

# => Once options have been processed, set variables to `readonly`.
readonly INPUT_IMAGE_FILE_NAME
readonly ICON_SETS_TO_OUTPUT
readonly OUTPUT_ICON_IMAGE_NAME_BASE
readonly ICON_SET_AUTHOR_NAME
readonly VERBOSE_LOGGING_ENABLED

####################################
####################################
####################################
# 2. Check input arguments are valid
####################################
####################################
####################################

logn "Validating input..."

# => Verify the input image is non-empty
if [[ -z "${INPUT_IMAGE_FILE_NAME}" ]]; then
  print_usage_and_exit $LINENO "Input Image required: \`--input <image-path>\`."
  exit 1
fi

# => Verify the input image actually has a file at that path.
if [[ ! -f "${INPUT_IMAGE_FILE_NAME}" ]]; then
  print_usage_and_exit $LINENO "No image at: '$(pwd)/${INPUT_IMAGE_FILE_NAME}'."
fi

if [[ ${#ICON_SETS_TO_OUTPUT[@]} -eq 0 ]]; then
  print_usage_and_exit $LINENO "Must pass at least one output flag."
fi

# => Verify at most one out of both padding and resizing was selected.
if [[ ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_RESIZING_FLAG}"* ) && \
      ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_PADDING_FLAG}"* ) ]]; then
  err $LINENO "Must select either image resizing or padding, got both options."
  exit 1
fi

# => Verify at most one out of both padding and cropping was selected.
if [[ ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_PADDING_FLAG}"* ) && \
      ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_CROPPING_FLAG}"* ) ]]; then
  err $LINENO "Must select either image padding or cropping, got both options."
  exit 1
fi

# => Verify at most one out of both resizing and cropping was selected.
if [[ ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_RESIZING_FLAG}"* ) && \
      ( "${EXTRA_FLAGS_STRING}" == *"${WHITELIST_CROPPING_FLAG}"* ) ]]; then
  err $LINENO "Must select either image resizing or cropping, got both options."
  exit 1
fi

# => Verify the Author output for the Icon Sets is non-empty.
if [[ -z "${ICON_SET_AUTHOR_NAME}" ]]; then
  err $LINENO "Must have non-empty argument for custom 'author' value."
  exit 1
fi

####################################
####################################
####################################
# 3. Begin looping over the Icon Set
#    Types that have been requested.
####################################
####################################
####################################

# This will loop over and generate each requested Icon Set type.
begin_generating_icon_sets_to_output

echo ""
echo "###############"
echo "## All done! ##"
echo "###############"
echo ""
