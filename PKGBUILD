pkgname=sys-scan
pkgver=0.2
pkgrel=1
pkgdesc="System Scanner"
arch=('any')
url="http://jaredparsons.com/"
license=('BSD')
depends=('perl')
source=(${pkgname}.pl)
sha256sums=('51ea02aa9f37c3437074ef7ad8891f174fe9f183b721946adc89ccf2062ae510')

package() {
  cd "$srcdir"

  install -D ${pkgname}.pl "$pkgdir/usr/bin/$pkgname"
}
