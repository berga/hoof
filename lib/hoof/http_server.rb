module Hoof
  class HttpServer < EventMachine::Connection
    include EventMachine::HttpServer

    def post_init
      super
      no_environment_strings
      @buffer = ''
    end

    def receive_data data
      @buffer << data
      super
    end

    def process_http_request
      p 'DATA'
      p @buffer
      begin
        host,port = @http_headers.scan(/Host:\s*([-a-zA-z\.\d]*):?(\d+)?\000/).flatten #[0][0].gsub(/:\d+$/, '')
        close_connection and return unless host =~ /.((dev)|(xip\.io))$/

        name = host.gsub(/\.((dev)|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b\.xip\.io))$/, '')
        application = Hoof.find name

        if application
          if application.static_file? @http_path_info
            puts "Serve static #{host}#{@http_request_uri}"
            send_data application.serve_static(@http_path_info)
            close_connection_after_writing
          else
            application.start
            puts "Serve #{host}#{@http_request_uri}"
            EventMachine.defer(proc {
              application.serve @buffer
            }, proc { |result|
              send_data result
              close_connection_after_writing
            })
          end
        else
          if name
            renderer = ERB.new(File.read(File.join(File.dirname(__FILE__),"..","templates","not_found.html.erb")))
            @title = "Application not found<br/>\"#{name}\""
            puts @title
            @application = application
            @host = host
            @port = port
            send_data renderer.result(binding)
            close_connection_after_writing
            return
          end
          close_connection
        end
      rescue => e
        puts e.message
        puts e.backtrace[0..10].join("\n")
        close_connection
      end
    end

  end
end
