# This is an Open Source project contributed to ONVIF Open Source Challenge: https://onvif-spotlight.bemyapp.com 

Use the project under the LGPL license to contact me for alternatives.

The project shows how to:
1. create a MacOS app

2. use Swift, Objective-C and C++ in the same project

3. use FFMPEG for video streaming and decoding

4. use ONVIFCamera and SOAPEngine open source libraries for ONVIF communication

5. detect Faces using new Apple Vision Framework

6. Use Model-View-Controller architecture.

-------------------

Project folder structure:
/app/             - the built application. Run in on your Mac

/FaceDetector/... - The meat of the project: View, Control, Parser and VideoSource classes

/ONVIFCamera/     - 3rd party libraries ONVIFCamera and SOAPEngine

-------------------

For convenience, the project includes ONVIFCamera and SOAPEngine open source libraries. You might want to get the latest versions for your setup instead.

Feel free to use your FFMPEG build and adjust project include/lib folders or follow the following procedure to setup FFMPEG in the expected location for building the project.
Run following commands in Terminal window:


#requirements

xcode-select --install

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install yasm

brew upgrade yasm


#donwloading

mkdir ~/dev

mkdir ~/dev/depends

mkdir ~/dev/depends/v5

mkdir ~/dev/3rd

rm -R ~/dev/3rd/ffmpeg

pushd ~/dev/3rd

curl http://ffmpeg.org/releases/ffmpeg-4.0.tar.bz2 > ffmpeg.tar.bz2

gunzip -c ffmpeg.tar.bz2 | tar xopf - 

rm ~/dev/3rd/ffmpeg.tar.bz2

mv ~/dev/3rd/ffmpeg-* ~/dev/3rd/ffmpeg

popd


#build

rm -R ~/dev/depends/v5/ffmpeg

pushd ~/dev/3rd/ffmpeg

export MACOSX_DEPLOYMENT_TARGET=10.9

./configure --prefix=$HOME/dev/depends/v5/ffmpeg --disable-programs --disable-doc --disable-avdevice --disable-audiotoolbox --disable-demuxer=matroska --disable-muxer=matroska --disable-securetransport --disable-xlib --disable-zlib --disable-iconv --disable-bzlib --disable-schannel --disable-decoders --enable-runtime-cpudetect --enable-decoder=jpeg2000 --enable-decoder=jpegls --enable-decoder=mjpeg --enable-decoder=mjpegb --enable-decoder=h264 --disable-encoders --enable-encoder=jpeg2000 --enable-encoder=jpegls --enable-encoder=mjpeg --extra-cflags="-mmacosx-version-min=10.9"

make install

popd
