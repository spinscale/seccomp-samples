require "option_parser"
require "http/server"
require "seccomp/seccomp"

seccomp = false
log = false
port = 8080

OptionParser.parse do |parser|
  parser.banner = "Usage: webserver [arguments]"
  parser.on("-s", "--seccomp", "Enable seccomp policy") { seccomp = true }
  parser.on("-l", "--log", "Log seccomp violation only") { log = seccomp = true }
  parser.on("-p PORT", "--port=PORT", "Use port, defaults to 8080") { |port_new| port = port_new.to_i32 }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end


# let's create an insecure webserver
server = HTTP::Server.new do |ctx|
  ctx.response.content_type = "text/plain"
  STDOUT.print "Incoming request: path #{ctx.request.path}\n"
  Process.run("/bin/ls", ["-al"]) do |proc|
    ctx.response.print proc.output.gets_to_end
  end
end

address = server.bind_tcp port
puts "Listening on http://#{address}"

# Move to secure state before accepting connections
if seccomp
  SeccompClient.new(log).run
end

server.listen

SCMP_ACT_LOG = 0x7ffc0000
class SeccompClient < Seccomp

  def initialize(@log : Bool)
  end

  def run : Int32
    ctx = uninitialized ScmpFilterCtx

    ctx = seccomp_init(SCMP_ACT_ALLOW)

    # stop executions
    action = @log ? SCMP_ACT_LOG : SCMP_ACT_ERRNO
    seccomp_rule_add(ctx, action, seccomp_syscall_resolve_name("execve"), 0)
    seccomp_rule_add(ctx, action, seccomp_syscall_resolve_name("execveat"), 0)
    seccomp_rule_add(ctx, action, seccomp_syscall_resolve_name("fork"), 0)
    seccomp_rule_add(ctx, action, seccomp_syscall_resolve_name("vfork"), 0)

    ret = seccomp_load(ctx);

    # optional, dump policy on stdout
    #ret = seccomp_export_pfc(ctx, STDOUT_FILENO)
    #printf("seccomp_export_pfc result: %d\n", ret)
    seccomp_release(ctx)
    ret < 0 ? -ret : ret
  end
end
