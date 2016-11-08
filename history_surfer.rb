# frozen_string_literal: true

ROOT = Pathname.new ARGV[0]
Dir.chdir ROOT
FILE_NAME = ARGV[1]

`git checkout master`

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

  def ==(o)
    @spec == o.spec
  end

  def to_s
    "(#{@lbegin}:#{@lend}):#{@spec}"
  end
end

# Represents the state of the world in a commit
class Commit
  @cache = {}

  attr_reader :sha, :specs

  def initialize(sha)
    @sha = sha
    @specs = Commit.collect_specs sha
  end

  # Take line beginning and end and find the corresponding stencil spec
  def search(lbegin, lend)
    @specs.find do |spec|
      spec.lbegin == lbegin && spec.lend == lend
    end
  end

  private

  def self.collect_specs(sha)
    `git checkout #{sha}^`

    if @cache[sha]
      @cache[sha]
    else
      output = `camfort stencils-infer #{FILE_NAME}`

      @cache[sha] =
        output.scan(/^\((\d+):+\d+\)-\((\d+):\d+\) \t(.*)$/).map do |lb, le, spec|
          StencilSpec.new spec, lb, le
        end
    end
  end
end

head = Commit.new `git rev-parse HEAD`.chomp

chains =
head.specs.map do |spec|
  output = `git log -L #{spec.lbegin},#{spec.lend}:#{FILE_NAME}`

  chain = [[head.sha, spec]]
  output.scan(/commit (\w+)$.*?@@ -\d+,\d+ \+(\d+),(\d+) @@/m) do |sha, lb, size|
    lbegin = lb.to_i
    commit = Commit.new sha
    s = commit.search(lbegin, lbegin + size.to_i - 1)

    # Make the chain more compact if the spec remains the same.
    chain.pop if chain.last && chain.last == s

    chain << [sha, s]
  end

  chain
end

chains.each do |chain|
  puts '-' * 80
  chain.each do |sha, spec|
    puts "#{sha}: #{spec}"
  end
end
