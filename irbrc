# The following gems are required: 
# hirb, wirble, what_methods, map_by_method, irb-history
# gem install hirb wirble what_methods map_by_method irb-history
[ 'pp', 'fileutils', 'rubygems', 'wirble', 'hirb', 'irb/completion', 
  'irb/ext/save-history', 'map_by_method', 
  'what_methods'].each do |library|
  begin
    require library
    case library
    when 'hirb'
      Hirb.enable 
      self.extend(Hirb::Console)
    when 'wirble'
      if ENV['IRB_COLOR']
        Wirble.init
        Wirble.colorize
      end  
    when 'fileutils'
      include FileUtils  
    end    
  rescue
    puts "Error loading #{library}"
    next
  end  
end

def log
  ActiveRecord::Base.clear_active_connections!
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

def mate *args
  flattened_args = args.map {|arg| "\"#{arg.to_s}\""}.join ' '
  `mate #{flattened_args}`
  nil
end

unless self.class.const_defined? "IRB_RC_HAS_LOADED"
  HISTFILE = "~/.irb.hist"
  MAXHISTSIZE = 1000

  begin # ANSI codes
    ANSI_BLACK    = "\033[0;30m"
    ANSI_GRAY     = "\033[1;30m"
    ANSI_LGRAY    = "\033[0;37m"
    ANSI_WHITE    = "\033[1;37m"
    ANSI_RED      = "\033[0;31m"
    ANSI_LRED     = "\033[1;31m"
    ANSI_GREEN    = "\033[0;32m"
    ANSI_LGREEN   = "\033[1;32m"
    ANSI_BROWN    = "\033[0;33m"
    ANSI_YELLOW   = "\033[1;33m"
    ANSI_BLUE     = "\033[0;34m"
    ANSI_LBLUE    = "\033[1;34m"
    ANSI_PURPLE   = "\033[0;35m"
    ANSI_LPURPLE  = "\033[1;35m"
    ANSI_CYAN     = "\033[0;36m"
    ANSI_LCYAN    = "\033[1;36m"

    ANSI_BACKBLACK  = "\033[40m"
    ANSI_BACKRED    = "\033[41m"
    ANSI_BACKGREEN  = "\033[42m"
    ANSI_BACKYELLOW = "\033[43m"
    ANSI_BACKBLUE   = "\033[44m"
    ANSI_BACKPURPLE = "\033[45m"
    ANSI_BACKCYAN   = "\033[46m"
    ANSI_BACKGRAY   = "\033[47m"

    ANSI_RESET      = "\033[0m"
    ANSI_BOLD       = "\033[1m"
    ANSI_UNDERSCORE = "\033[4m"
    ANSI_BLINK      = "\033[5m"
    ANSI_REVERSE    = "\033[7m"
    ANSI_CONCEALED  = "\033[8m"

    XTERM_SET_TITLE   = "\033]2;"
    XTERM_END         = "\007"
    ITERM_SET_TAB     = "\033]1;"
    ITERM_END         = "\007"
    SCREEN_SET_STATUS = "\033]0;"
    SCREEN_END        = "\007"
  end

  begin # Persistent command history
    if defined? Readline::HISTORY
      histfile = File::expand_path( HISTFILE )
      if File::exists?( histfile )
        lines = IO::readlines( histfile ).collect {|line| line.chomp}
        puts "Read %d saved history commands from %s." %
          [ lines.nitems, histfile ] if $DEBUG || $VERBOSE
        Readline::HISTORY.push( *lines )
      else
        puts "History file '%s' was empty or non-existant." %
          histfile if $DEBUG || $VERBOSE
        touch histfile 
      end

      Kernel::at_exit {
        lines = Readline::HISTORY.to_a.reverse.uniq.reverse
        lines = lines[ -MAXHISTSIZE, MAXHISTSIZE ] if lines.nitems > MAXHISTSIZE
        $stderr.puts "Saving %d history lines to %s." % [ lines.length, histfile ] if $VERBOSE || $DEBUG
        File::open( histfile, File::WRONLY|File::CREAT|File::TRUNC ) {|ofh|
          lines.each {|line| ofh.puts line }
        }
      }
    end
  end

  begin 
    def history(how_many = 50)
      history_size = Readline::HISTORY.size

      # no lines, get out of here
      puts "No history" and return if history_size == 0

      start_index = 0

      # not enough lines, only show what we have
      if history_size <= how_many
        how_many  = history_size - 1
        end_index = how_many
      else
        end_index = history_size - 1 # -1 to adjust for array offset
        start_index = end_index - how_many 
      end

      start_index.upto(end_index) {|i| print_line i}
      nil
    end
    alias :h  :history

    # -2 because -1 is ourself
    def history_do(lines = (Readline::HISTORY.size - 2))
      irb_eval lines
      nil
    end 
    alias :h! :history_do

    def history_write(filename, lines)
      file = File.open(filename, 'w')

      get_lines(lines).each do |l|
        file << "#{l}\n"
      end

      file.close
    end
    alias :hw :history_write

    def get_line(line_number)
      Readline::HISTORY[line_number]
    end

    def get_lines(lines = [])
      return [get_line(lines)] if lines.is_a? Fixnum
      out = []
      lines = lines.to_a if lines.is_a? Range
      lines.each do |l|
        out << Readline::HISTORY[l]
      end

      return out
    end

    def print_line(line_number, show_line_numbers = true)
      print "[%04d] " % line_number if show_line_numbers
      puts get_line(line_number)
    end

    def irb_eval(lines)
      to_eval = get_lines(lines)
      eval to_eval.join("\n")
      to_eval.each {|l| Readline::HISTORY << l}
    end
  end

  begin # Utility methods
    def pm(obj, *options) # Print methods
      methods = obj.methods
      methods -= Object.methods unless options.include? :more
      filter = options.select {|opt| opt.kind_of? Regexp}.first
      methods = methods.select {|name| name =~ filter} if filter

      data = methods.sort.collect do |name|
        method = obj.method(name)
        if method.arity == 0
          args = "()"
        elsif method.arity > 0
          n = method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")})"
        elsif method.arity < 0
          n = -method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")}, ...)"
        end
        klass = $1 if method.inspect =~ /Method: (.*?)#/
        [name, args, klass]
      end
      max_name = data.collect {|item| item[0].size}.max
      max_args = data.collect {|item| item[1].size}.max
      data.each do |item| 
        print " #{ANSI_BOLD}#{item[0].rjust(max_name)}#{ANSI_RESET}"
        print "#{ANSI_GRAY}#{item[1].ljust(max_args)}#{ANSI_RESET}"
        print "   #{ANSI_LGRAY}#{item[2]}#{ANSI_RESET}\n"
      end
      data.size
    end
  end
  
  script_console_running = ENV.include?('RAILS_ENV') && IRB.conf[:LOAD_MODULES] && IRB.conf[:LOAD_MODULES].include?('console_with_helpers')
  rails_running = ENV.include?('RAILS_ENV') && !(IRB.conf[:LOAD_MODULES] && IRB.conf[:LOAD_MODULES].include?('console_with_helpers'))
  irb_standalone_running = !script_console_running && !rails_running

  if script_console_running
    require 'logger'
    Object.const_set(:RAILS_DEFAULT_LOGGER, Logger.new(STDOUT))
  end

  ARGV.concat [ "--readline" ]
  IRB_RC_HAS_LOADED = true
end