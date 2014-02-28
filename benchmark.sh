RESULTSD=results.$$
REPETITIONS=5

function install_lame() {
    srcdir="$1"
    prefix="$2"

    url="http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"
    wget $url -O - | tar -xzf - -C "$srcdir"

    cd src/lame-3.99.5/
    ./configure --prefix="$prefix"
    make && make install
    cd -
}

function install_bzip2() {
    srcdir="$1"
    prefix="$2"

    url="http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
    wget $url -O - | tar -xzf - -C "$srcdir"

    cd src/bzip2-1.0.6
    make && make install PREFIX="$prefix"
    cd -
}

function install_ffmpeg() {
    srcdir="$1"
    prefix="$2"

    url="ffmpeg.gusari.org/static/64bit/ffmpeg.static.64bit.2013-10-03.tar.gz"
    wget $url -O - | tar -xzf - -C "$prefix/bin"
}


function run_benchmark_command() {
    cmd="$1"
    out="$2"
    res="$3"

    for i in $(seq 1 $REPETITIONS); do
        { time $cmd; } 2>> "$res"
        rm "$out"
    done
}

function benchmark_wav_to_mp3() {
    lame="$1"
    wav="$2"
    mp3="${wav%%.wav}.mp3"
    results="$RESULTSD/wav_to_mp3"

    if [ -f "$mp3" ]; then
        rm "$mp3"
    fi

    run_benchmark_command \
        "$lame -h --quiet $wav" \
        "$mp3" \
        "$results"
}

function benchmark_bzip2_compress() {
    bzip2="$1"
    in="$2"
    results="$RESULTSD/bzip2"

    run_benchmark_command \
        "bzip2 -k $in" \
        "$in.bz2" \
        "$results"
}

function benchmark_ogv_to_mp4() {
    ffmpeg="$1"
    ogv="$2"
    mp4="${ogv%%.ogv}.mp4"
    results="$RESULTSD/ogv_to_mp4"

    if [ -f "$mp4" ]; then
        rm "$mp4"
    fi

    run_benchmark_command \
        "$ffmpeg -v quiet -i $ogv -strict -2 $mp4" \
        "$mp4" \
        "$results"
}

if [ ! -d src -o ! -d prefix ]; then
    rm -rfv src && mkdir src
    rm -rfv prefix && mkdir prefix{,/bin}
    install_lame "$PWD/src" "$PWD/prefix"
    install_bzip2 "$PWD/src" "$PWD/prefix"
    install_ffmpeg "$PWD/src" "$PWD/prefix"
fi

echo $RESULTSD
if [ -d "$RESULTSD" ]; then
    rm -rf "$RESULTSD"
fi

mkdir "$RESULTSD"
benchmark_wav_to_mp3 prefix/bin/lame data/shsof1601.wav
benchmark_bzip2_compress prefix/bin/bzip2 data/sample.tar
benchmark_ogv_to_mp4 prefix/bin/ffmpeg data/elephants_dream1.ogv
