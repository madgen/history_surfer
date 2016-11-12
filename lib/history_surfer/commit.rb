# frozen_string_literal: true

require 'history_surfer/stencil_spec'
require 'history_surfer/util'

class HistorySurfer
  # Represents the state of the world in a commit
  class Commit
    include HistorySurfer::Util

    STENCIL_R = /^\((\d+):\d+\)-\((\d+):\d+\) {4}(.*)$/

    @cache = {}
    class << self; attr_accessor :cache; end

    attr_reader :sha, :specs

    def initialize(sha)
      @sha = sha
      @specs = (Commit.cache[sha] ||= Commit.collect_specs(sha))
    end

    # Take line beginning and end and find the corresponding stencil spec
    def search(lbegin, lend)
      @specs.select do |spec|
        spec.lbegin == lbegin && spec.lend == lend
      end
    end

    def short_sha
      @sha[0...7]
    end

    private_class_method

    def self.collect_specs(sha)
      dispatch("git checkout #{sha}")

      success, output = dispatch("~/.local/bin/camfort stencils-infer #{FILE_NAME}")
      return [] unless success

      output.scan(STENCIL_R).map do |lb, le, spec|
        raise 'Specification not properly parsed.' unless lb && le && spec
        StencilSpec.new spec, lb, le
      end
    end
  end
end
