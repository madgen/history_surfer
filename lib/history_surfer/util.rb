# frozen_string_literal: true

require 'English'
require 'tempfile'

class HistorySurfer
  # Utility functions
  module Util
    def dispatch(command)
      Tempfile.open do |tmp|
        pid = spawn command, out: tmp.path, err: File::NULL
        Process.wait pid
        tmp.flush
        [$CHILD_STATUS.success?, tmp.read]
      end
    end
  end
end
