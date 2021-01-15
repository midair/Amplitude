# Amplitude
_Amplitude App Icon Generator_

**Generate iOS App, iOS Sticker Pack, WatchOS App and MacOS App Icon Sets.**

This script will generate Icon Sets that can be imported into Xcode from a single input image.

For best results, the input image should be **1024px x 1024px**. The script supports resizing, cropping or padding the input image if needed.

## Installation

1. Clone the generator.

```bash
$ git clone https://github.com/midair/Amplitude-Icon-Generator.git
```

2. Make the generator script executable.

```bash
$ chmod a+x Amplitude-Icon-Generator/make-icons.sh
```

3. Add an alias to run the generator.

_In your `~/.bashrc`, add:_ 
```
alias amplitude-icons=[insert path to]/Amplitude-Icon-Generator/make-icons.sh
```
NOTE: Replace `[insert path to]` with the qualified path to the location where you cloned `Amplitude-Icon-Generator`.

## Usage

1. Create an image that you want to be used to generate the icons.

For best results, use a square image that is `1024px x 1024px` or larger.

2. Navigate to the directory where you want the Icon Sets to be generated.

3. Call the generator script with the desired output types.

```bash
$ amplitude-icons --input <insert-your-input-image-name>.png --output-default IOS --output-default STICKER
```

Supported output types are: `IOS`, `STICKER`, `WATCH`, and `MAC`.
