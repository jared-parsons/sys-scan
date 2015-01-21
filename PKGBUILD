pkgname=sys-scan
pkgver=0.1
pkgrel=1
pkgdesc="System Scanner"
arch=('any')
url="http://jaredparsons.com/"
license=('BSD')
depends=('perl')
source=(${pkgname}.pl)
sha256sums=('472e3cf4692035c8d207ba75c549780b72bca6dd9bccbbc1b1c06747a111418b')

package() {
  cd "$srcdir"

  install -D ${pkgname}.pl "$pkgdir/usr/bin/$pkgname"
}
