module StepUp
  module NotesUtil
    def parse_message(message)
      message = message.rstrip.force_encoding('utf-8').gsub(/^((?:  )*)( )?([^ \-\n])/){ "%s  %s %s" % [$1, $2 || '-', $3] }
      begin
        changed = message.sub!(/^(\s*-\s.*?\n)(?:\s*\n)+(\s*-\s)/, '\1\2')
      end until changed.nil?
      message
    end
    extend self
  end
end
