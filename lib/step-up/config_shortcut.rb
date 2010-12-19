module StepUp
  module ConfigShortcut
    def method_missing(m, *args, &block)
      if m.to_s =~ /^__(.*)$/
        attribute = $1
        CONFIG.key?(attribute) ? CONFIG.send(attribute) : super
      else
        super
      end
    end

    def __notes_sections
      CONFIG.notes_sections
    end
  end
end
