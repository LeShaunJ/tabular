require "./spec_helper"
require "../src/tabular/version"
require "semantic_version"
require "yaml"

alias SemVer = SemanticVersion

struct SemanticVersion
  # Ensure human-readable output
  def inspect(io : IO)
    to_s io
  end
end

Spectator.describe Tabular::VERSION, :version do
  let(current) { SemVer.parse(Tabular::VERSION) }
  let(latest) {
    args = %w(ls-remote -t --sort -v:refname --refs --exit-code origin)
    proc = Process.new "git", args, output: PIPE, error: PIPE
    stdout = proc.output.gets || ""
    stderr = proc.error.gets_to_end
    status = proc.wait

    case status.exit_code?
    when 0 then SemVer.parse(stdout.split(/\/v/)[-1])
    when 2 then SemVer.parse("0.0.0")
    else        raise RuntimeError.from_errno(stderr)
    end
  }
  let(shard) {
    File.open "shard.yml" do |file|
      YAML.parse(file.gets_to_end)
    end
  }

  it "is higher than the latest release" do
    expect(current).to be_gt(latest)
  end

  it "is set in shard.yml" do
    expect(shard["version"]?).to eq(current.to_s)
  end
end
