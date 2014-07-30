require './app'
require './middlewares/sock_backend'

$stdout.sync = true

use Schleifer::SockBackend

run Schleifer::App
