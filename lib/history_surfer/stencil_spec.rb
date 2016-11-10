# frozen_string_literal: true

class HistorySurfer
  # Stencil specification representation
  class StencilSpec
    attr_reader :spec, :lbegin, :lend

    def initialize(spec, lbegin, lend)
      @spec = spec
      @lbegin = lbegin.to_i
      @lend = lend.to_i
    end

    def span_len
      @lend - @lbegin
    end

    def ==(other)
      @spec == other.spec
    end

    def to_s
      "(#{@lbegin}:#{@lend}):#{@spec}"
    end
  end
end
