PKGTITLE="gcs_jpdiagnostics"
PKGVERSION=1.0
PKGID="com.jamf.gcs.jpdiagnostics"
PROJECT="gcs_jpdiagnostics"
DeveloperID=""

clean:
	rm -f ./${PKGTITLE}-*.pkg
	rm -rf pkgroot
	rm -rf ./signed

pkg: clean
	mkdir -p pkgroot/opt
	mkdir ./signed
	cp ~/.boto pkgroot/opt/
	chmod 400 pkgroot/opt/.boto
	pkgbuild --root pkgroot --identifier ${PKGID} --version ${PKGVERSION} ./${PKGTITLE}-${PKGVERSION}.pkg
#	productsign --sign ${DeveloperID} ${PKGTITLE}-${PKGVERSION}.pkg signed/${PKGTITLE}-${PKGVERSION}.pkg