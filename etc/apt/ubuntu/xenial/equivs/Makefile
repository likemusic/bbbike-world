# files to build simple debian meta packages
#
# http://wiki.debian.org/CreateDummyPackage
# equivs-build package-minimal 

#
# all meta packages, "bbbike-world" is the top-level
#
ALL= 	bbbike-world \
	bbbike-world-debian-meta \
	bbbike-world-debian-meta-dev \
	bbbike-world-perlmodules-meta

all:
	for i in ${ALL}; do \
	  echo `pwd`/$$i; \
	done

