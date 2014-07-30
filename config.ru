require './app'
require './middlewares/sock_backend'

use SockDemo::SockBackend

run SockDemo::App
