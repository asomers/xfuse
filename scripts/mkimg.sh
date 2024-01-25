#! /bin/sh -e

# Recreate the golden image used for the integration tests

mkfiles() {
	DIR=$1
	COUNT=$2

	mkdir $DIR
	for i in $(seq -f "%06g" 0 $(( COUNT - 1 )) ); do
		touch "$DIR/frame${i}"
	done
}

mkattrs() {
	FILE=$1
	COUNT=$2

	touch $FILE
	for i in $(seq -f "%06g" 0 $(( COUNT - 1 )) ); do
		setfattr -n user.attr.${i} -v value.${i} $FILE
	done
}

truncate -s 32m resources/xfs.img
mkfs.xfs --unsupported -n size=8192 -f resources/xfs.img
MNTDIR=`mktemp -d`
mount -t xfs resources/xfs.img $MNTDIR

mkfiles ${MNTDIR}/sf 2
mkfiles ${MNTDIR}/block 32
mkfiles ${MNTDIR}/leaf 384
mkfiles ${MNTDIR}/node 1024
mkfiles ${MNTDIR}/btree 8192

mkdir ${MNTDIR}/xattrs
mkattrs ${MNTDIR}/xattrs/local 4
mkattrs ${MNTDIR}/xattrs/extents 64
# TODO: figure out how to force the xattrs to be allocated as a btree.
# Sequentially allocating as many ask 256k xattrs doesn't do it.

mkdir ${MNTDIR}/links
ln -s dest ${MNTDIR}/links/sf
ln -s 0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDE ${MNTDIR}/links/max

mkdir ${MNTDIR}/files
echo "Hello, World!" > ${MNTDIR}/files/hello.txt
touch -t  198209220102.03 ${MNTDIR}/files/hello.txt # Set mtime to my birthday
touch -at 201203230405.06 ${MNTDIR}/files/hello.txt # Set atime to my kid's birthday
ln ${MNTDIR}/files/hello.txt ${MNTDIR}/files/hello2.txt
chown 1234:5678 ${MNTDIR}/files/hello.txt
chmod 01234 ${MNTDIR}/files/hello.txt
touch -t 191811111111.11 ${MNTDIR}/files/old.txt    # Armistice day
mkfifo ${MNTDIR}/files/fifo
python3 -c "import socket as s; sock = s.socket(s.AF_UNIX); sock.bind('${MNTDIR}/files/sock')"
mknod ${MNTDIR}/files/blockdev b 1 2
mknod ${MNTDIR}/files/chardev c 1 2

umount ${MNTDIR}

rmdir $MNTDIR

zstd -f resources/xfs.img
