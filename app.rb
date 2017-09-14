require 'os'
require 'sinatra'
require 'sentry_breakpad'
require 'raven'
require 'rdiscount'


get '/' do
  markdown File.read("./README.md")
end


post '/crashreport' do
  unless params[:upload_file_minidump] and params[:upload_file_minidump][:filename]
    halt 400, "Need to pass minidump upload"
  end

  # Electron sends us crash reports in the minidump format.
  # We need to read them and run minidump_stackwalk to be
  # able to see them in an intelligible format.
  file = params[:upload_file_minidump][:tempfile]
  tmpfile = Tempfile.new('minidump')

  begin
    tmpfile.write(file.read)

    res = ''
    if OS.mac?
      res = `./minidump_stackwalk_mac #{tmpfile.path}`
    if Os.windows?
      res = `./minidump_stackwalk_win32 #{tmpfile.path}`
    elsif OS.linux? and OS.bits == 64
      res = `./minidump_stackwalk_linux64 #{tmpfile.path}`
    end

    SentryBreakpad.send_from_string(res)
    puts "reported to sentry"
  ensure
    tmpfile.close
    tmpfile.unlink
  end

  return 'ok'
end
