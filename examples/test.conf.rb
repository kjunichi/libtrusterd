#
# Trusterd - HTTP/2 Web Server scripting with mruby
#
# Copyright (c) MATSUMOTO, Ryosuke 2014 -
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
#

SERVER_NAME = "Trusterd"
SERVER_VERSION = "0.0.1"
SERVER_DESCRIPTION = "#{SERVER_NAME}/#{SERVER_VERSION}"

root_dir = "."

s = HTTP2::Server.new({

  #
  # required config
  #

  :port           => 8080,
  :document_root  => "#{root_dir}/htdocs",
  :server_name    => SERVER_DESCRIPTION,

  # support prefork only when linux kernel supports SO_REUSEPORT
  # :worker         => 1,
 :worker         => "auto",

  # required when tls option is true.
  # tls option is true by default.
  :key            => "#{root_dir}/ssl/key.pem",
  :crt            => "#{root_dir}/ssl/cert.pem",

  # listen ip address
  # default value is 0.0.0.0
  # :server_host  => "127.0.0.1",

  #
  # optional config
  #

  # debug default: false
  # :debug  =>  true,

  # tls default: true
    :tls => false,

  # damone default: false
  # :daemon => true,

  # callback default: false
   :callback => true,

  # connection_record defualt: true
  # :connection_record => false,

})

#
# when :callback option is true,
#
 s.set_map_to_storage_cb {
#
#   p "callback bloack at set_map_to_strage_cb"
#   p s.request.uri
#   p s.request.filename
#
#   # location setting
#   if s.request.uri == "/index.html"
#     s.request.filename = "#{root_dir}/htdocs/hoge"
#   end
#   p s.request.filename
#
#   # you can use regexp if you link regexp mrbgem.
#   # Or, you can use KVS like mruby-redis or mruby-
#   # vedis and so on.
#
#   # Experiment: reverse proxy config
#   # reciev front end with HTTP/2 and proxy upstream server with HTTP/1
#   # TODO: reciev/send headers transparently and support HTTP/2 at upstream
#
#   if s.request.uri =~ /^\/upstream(\/.*)/
#     s.upstream_uri = $1
#     s.upstream = “http://127.0.0.1“
#   end
#
#   # dynamic content with mruby
#   if s.request.filename =~ /^.*\.rb$/
#     s.enable_mruby
#   end
#
#   # dynamic content with mruby sharing mrb_state
#   if s.request.filename =~ /^.*\_shared.rb$/
#     s.enable_shared_mruby
#   end
if s.request.uri == "/cgi"
  p s.request
  p "cgi"

  s.set_content_cb {
    s.rputs s.unparsed_uri+"\n"
    if s.body
      s.rputs s.body+"\n"
    end
    myres = Libtrusterd::Cgi.cgi_proc("{uri:hoge,param:1}")
    s.rputs("retrun = ["+myres+"]\n")
    myres = ""
  }
end

if s.request.uri == "/test"
  #p s.request
  #p "test"
  #MyCall.my_exec("this is trusterd!")

  $counter = $counter + 1
  if ($counter%100000==0)
    #GC.start
  end

  s.set_content_cb {
    s.rputs s.unparsed_uri+"\n"
    #if s.body
    #  s.rputs s.body+"\n"
    #end
    s.rputs "hello trusterd!"
  }
end

if s.request.uri == "/exit"
  p "exit"
  s.set_content_cb {
    s.rputs s.unparsed_uri+"\n"
    s.rputs "Good bye trusterd!"
  }
  f = open("libtrusterd.pid","r")
  pid = f.read
  f.close
   puts "now kill pid = " + pid.to_s
  Process.fork {
    sleep(0.5)
    Process.kill('SIGTERM',pid.to_i)
    Process.waitpid(pid.to_i)
    puts "Now all done,so I'm gonna exit."
    exit(0)
  }
end
#
if s.request.uri == "/ldd"
  s.set_content_cb {
    puts "/ldd start"

    s.rputs Libtrusterd::Util.ldd
  }
end
#
}

# s.set_content_cb {
#   s.rputs "hello trusterd world from cb"
#   s.echo "+ hello trusterd world from cb with \n"
# }

#
# f = File.open "#{root_dir}/logs/access.log", "a"
#
# s.set_logging_cb {
#
#   p "callback block after send response"
#   f.write "#{s.conn.client_ip} #{Time.now} - #{s.r.uri} - #{s.r.filename}\n"
#
# }
$counter=1
s.run
p 123
