PKGTITLE="aws_aftermath"
PKGVERSION=1.0
PKGID="com.jamf.aws.aftermath"
PROJECT="aws_aftermath"
DeveloperID=""

clean:
	rm -f ./${PKGTITLE}-*.pkg
	rm -rf pkgroot
	rm -rf ./signed

pkg: clean
	mkdir -p pkgroot/opt
	mkdir ./signed
	cp -r ~/.aws pkgroot/opt/
	chmod -R 400 pkgroot/opt/.aws
	pkgbuild --root pkgroot --identifier ${PKGID} --version ${PKGVERSION} ./${PKGTITLE}-${PKGVERSION}.pkg
#	productsign --sign ${DeveloperID} ${PKGTITLE}-${PKGVERSION}.pkg signed/${PKGTITLE}-${PKGVERSION}.pkg