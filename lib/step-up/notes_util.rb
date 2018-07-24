module StepUp
  module NotesUtil
    def parse_message(message)
      message = safe_gsub(message.rstrip.force_encoding("UTF-8")){ |m| m.gsub(/^((?:  )*)( )?([^ \-\n])/){ "%s  %s %s" % [$1, $2 || '-', $3] } }
      begin
        changed = message.sub!(/^(\s*-\s.*?\n)(?:\s*\n)+(\s*-\s)/, '\1\2')
      end until changed.nil?
      message
    end

    def safe_gsub(message)
      begin
        yield message
      rescue Exception => e
        if e.message.start_with?('invalid byte')
          yield(message.force_encoding('ISO-8859-1').encode('UTF-8'))
        else
          raise e
        end
      end
    end
    extend self
  end
end
