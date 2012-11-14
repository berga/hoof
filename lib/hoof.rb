require 'eventmachine'
require 'unicorn/launcher'
require 'evma_httpserver'
require 'erb'

require 'hoof/http_server'
require 'hoof/https_server'
require 'hoof/control_server'
require 'hoof/application'
require 'hoof/application_pool'

module Hoof

  def self.pool
    @pool ||= begin
      app_pool = Hoof::ApplicationPool.new
      app_pool.reload
      app_pool
    end
  end

  def self.find name
    pool[name]
  end

  def self.start
   EventMachine.epoll
   EventMachine::run do
     trap("TERM") { stop }
     trap("INT")  { stop }

     #default: EventMachine::start_server "127.0.0.1", http_port, Hoof::HttpServer
     EventMachine::start_server "0.0.0.0", http_port, Hoof::HttpServer
     EventMachine::start_server "0.0.0.0", https_port, Hoof::HttpsServer
     EventMachine::start_server sock, Hoof::ControlServer
   end
  end

  def self.stop
    pool.stop
    EventMachine.stop
  end

  def self.sock
    File.expand_path(File.join('~/.hoof', 'hoof.sock'))
  end

  def self.http_port
    26080
  end

  def self.https_port
    26443
  end

end
