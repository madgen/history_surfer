# frozen_string_literal: true

require 'history_surfer/stencil_spec'
require 'history_surfer/util'

class HistorySurfer
  # Represents the state of the world in a commit
  class Commit
    include HistorySurfer::Util

    STENCIL_R = /^\((\d+):\d+\)-\((\d+):\d+\) {4}(.*)$/

    @cache = {}

    attr_reader :sha, :specs

    def initialize(sha)
      @sha = sha
      @specs = Commit.collect_specs sha
    end

    # Take line beginning and end and find the corresponding stencil spec
    def search(lbegin, lend)
      @specs.select do |spec|
        spec.lbegin == lbegin && spec.lend == lend
      end
    end

    private_class_method

    def self.collect_specs(sha)
      dispatch("git checkout #{sha}")

      if @cache[sha]
        @cache[sha]
      else
        success, output = dispatch("~/.local/bin/camfort stencils-infer #{FILE_NAME}")

        @cache[sha] =
          if success
            output.scan(STENCIL_R).map do |lb, le, spec|
              raise 'Specification not properly parsed.' unless lb && le && spec
              StencilSpec.new spec, lb, le
            end
          else
            []
          end
      end
    end
  end
end
