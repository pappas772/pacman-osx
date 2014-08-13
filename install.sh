#!/usr/bin/env bash
#
# Compiling Pacman on OS X 10.10 Yosemite
#
# Kyle Ladd <kyle@laddk.com>
# 2014-08-01 02:06:22
#
# install.sh
#

PACMANPREFIX=/usr/local

function in_parallel()
{
	declare -a pargs=("${!1}")

	for ((i = 0; i < ${#pargs[@]}; i++)); do
		eval "${pargs[$i]}" &
	done

	wait
}

function in_serial()
{
	declare -a sargs=("${!1}")

	for ((i = 0; i < ${#sargs[@]}; i++)); do
		eval "${sargs[$i]}"
		# echo "${sargs[$i]}"
	done
}

function main()
{
	tmpdir=$(mktemp -d /tmp/tmp.XXXXXX)
	PATH=$tmpdir/bin:$PATH

	download_sources=(
		"curl -O https://ftp.gnu.org/gnu/gettext/gettext-0.19.2.tar.xz"
		"curl -O http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz"
		"curl -O http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz"
		"curl -O http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz"
		"curl -O http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz"
		"curl -O http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz"
		"curl -LO https://github.com/libarchive/libarchive/archive/v2.8.3.tar.gz"
		"curl -LO http://downloads.sourceforge.net/project/asciidoc/asciidoc/8.6.9/asciidoc-8.6.9.tar.gz"
		"git clone git://projects.archlinux.org/pacman.git"
		"git clone git://github.com/kladd/pacman-osx-pkgs.git"
	)

	extract_sources=(
		"tar -xJvf gettext-0.19.2.tar.xz"
		"tar -xzvf automake-1.14.1.tar.gz"
		"tar -xzvf autoconf-2.69.tar.gz"
		"tar -xzvf pkg-config-0.28.tar.gz"
		"tar -xzvf libtool-2.4.2.tar.gz"
		"tar -xzvf bash-4.3.tar.gz"
		"tar -xzvf v2.8.3.tar.gz"
		"tar -xzvf asciidoc-8.6.9.tar.gz"
	)


	# Download package sources
	echo "Downloading dependencies..."
	in_parallel download_sources[@]

	# Extract sources
	echo "Extracting dependencies..."
	in_parallel extract_sources[@]


	pushd $tmpdir/gettext-0.19.2 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/automake-1.14.1 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/autoconf-2.69 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/pkg-config-0.28 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/libtool-2.4.2 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/bash-4.3 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/libarchive-2.8.3 || exit
	./build/autogen.sh
	./configure --prefix=$tmpdir
	make
	make install
	popd

	pushd $tmpdir/asciidoc-8.6.9 || exit
	./configure --prefix=$tmpdir
	make
	make install
	popd

	# compile Pacman
	pushd $tmpdir/pacman
	LIBARCHIVE_CFLAGS="-I$tmpdir/include"
	LIBARCHIVE_LIBS="-larchive"
	LIBCURL_CFLAGS="-I/usr/include/curl"
	LIBCURL_LIBS="-lcurl"

	PATH=$tmpdir/bin:$PATH ./autogen.sh
	PATH=$tmpdir/bin:$PATH ./configure --prefix=$PACMANPREFIX \
		--enable-doc \
		--with-scriptlet-shell=$tmpdir/bin/bash \
		--with-curl
	make
	make -C contrib
	make install
	make -C contrib install
	popd
}

echo "This is going to look really ugly..."
main
$PACMANPREFIX/bin/pacman --version

cat << EOF

With pacman now installed, you should use it to install the packaged
version of pacman along with its dependencies.

Those packages can be found at:

	https://github.com/kladd/pacman-osx-pkgs

This will allow pacman to update itself in the future.
EOF

