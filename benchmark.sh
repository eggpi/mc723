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

function install_imagemagick()
{
    srcdir="$1"
    prefix="$2"
    
    url="http://www.imagemagick.org/download/ImageMagick.tar.gz"
    wget $url -O - | tar -xzf - -C "$srcdir"
    
    cd src/ImageMagick-6.8.8-7
    ./configure --prefix="$prefix"
    make && make install
    cd -
}

function install_ffmpeg() {
    srcdir="$1"
    prefix="$2"

    url="ffmpeg.gusari.org/static/64bit/ffmpeg.static.64bit.2013-10-03.tar.gz"
    wget $url -O - | tar -xzf - -C "$prefix/bin"
}

function install_gpg() {
    srcdir="$1"
    prefix="$2"
    url="http://ftp.us.debian.org/debian/pool/main/g/gnupg/gnupg_1.4.12-7+deb7u3_amd64.deb"

    cd "$srcdir"
    wget $url -O gnupg_1.4.12.deb
    ar x gnupg_1.4.12.deb data.tar.gz
    tar --strip-components=2 -C "$prefix" -xzf data.tar.gz ./usr/bin/gpg
    cd "$OLDPWD"
}

function run_benchmark_command() {
    cmd="$1"
    out="$2"
    res="$3"

    if [ -f "$out" ]; then
        rm -f "$out"
    fi

    for i in $(seq 1 $REPETITIONS); do
        { time $cmd; } 2>&1 | sed -n 's/real[ \t]*//p' >> "$res"
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
        "$bzip2 -k $in" \
        "$in.bz2" \
        "$results"
}

function benchmark_ogv_to_mp4() {
    ffmpeg="$1"
    ogv="$2"
    mp4="${ogv%%.ogv}.mp4"
    results="$RESULTSD/ogv_to_mp4"

    run_benchmark_command \
        "$ffmpeg -v quiet -i $ogv -strict -2 $mp4" \
        "$mp4" \
        "$results"
}

function benchmark_gpg_encrypt() {
    # gpg fails unless called from inside prefix/bin
    prefix=$(dirname "$1")
    data="$PWD/$2"
    encrypted="${data}.asc"
    results="$PWD/$RESULTSD/gpg_encrypt"

    passphrase=$(mktemp)
    echo secret passphrase > "$passphrase"

    cd "$prefix"
    run_benchmark_command \
        "gpg -q --passphrase-file $passphrase --symmetric -a $data" \
        "$encrypted" \
        "$results"

    rm "$passphrase"
    cd "$OLDPWD"
}

if [ ! -d src -o ! -d prefix ]; then
    rm -rfv src && mkdir src
    rm -rfv prefix && mkdir prefix{,/bin}
    install_lame "$PWD/src" "$PWD/prefix"
    install_bzip2 "$PWD/src" "$PWD/prefix"
    install_ffmpeg "$PWD/src" "$PWD/prefix"
    install_gpg "$PWD/src" "$PWD/prefix"
    install_imagemagick "$PWD/src" "$PWD/prefix"
fi

echo $RESULTSD
if [ -d "$RESULTSD" ]; then
    rm -rf "$RESULTSD"
fi

mkdir "$RESULTSD"
tar -c data/home/* -f data/home.tar
benchmark_gpg_encrypt prefix/bin/gpg data/home.tar
benchmark_wav_to_mp3 prefix/bin/lame data/dracula_01_stoker.wav
benchmark_bzip2_compress prefix/bin/bzip2 data/home.tar
benchmark_ogv_to_mp4 prefix/bin/ffmpeg data/elephants_dream1.ogv
benchmark_png_to_jpeg prefix/bin data/imagem.png
