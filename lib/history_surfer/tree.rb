# frozen_string_literal: true

require 'history_surfer/commit'

class HistorySurfer
  # Tree structure to keep track of spec differences.
  class Tree
    LOG_R = /commit (\w+)$.*?@@ -\d+,\d+ \+(\d+),(\d+) @@/m

    def initialize(commit, spec, gitlog)
      @family_chain = []
      gitlog.scan(LOG_R) do |sha, lb, size|
        lbegin = lb.to_i
        lend = lbegin + size.to_i - 1
        @family_chain << [sha, lbegin, lend]
      end
      @root = Node.new commit, spec, @family_chain
    end

    def to_s
      @root.to_s
    end

    # Internal node representation for the tree
    class Node
      def initialize(commit, spec, family_chain, depth = 0)
        @commit = commit
        @spec = spec
        @depth = depth
        @children = find_children family_chain
      end

      def to_s
        s = StringIO.new
        s.puts "#{' ' * (@depth * 2)}#{@commit.sha} #{@spec}"
        s.puts @children
        s.string
      end

      private

      def find_children(family_chain)
        return [] if family_chain.nil? || family_chain.empty?

        head, *tail = family_chain
        sha, lbegin, lend = head

        commit = Commit.new(sha)
        potential_specs = commit.search lbegin, lend

        same_spec_as_parent = potential_specs.find { |spec| spec == @spec }

        if same_spec_as_parent
          [Node.new(commit, same_spec_as_parent, tail, @depth + 1)]
        else
          parents_potential_specs = @commit.search(@spec.lbegin, @spec.lend)
          (potential_specs - parents_potential_specs).map do |spec|
            Node.new commit, spec, tail, @depth + 1
          end
        end
      end
    end
  end
end
