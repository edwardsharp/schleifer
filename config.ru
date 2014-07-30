require './app'
require './middlewares/sock_backend'

$stdout.sync = true

use SockDemo::SockBackend

run SockDemo::App
