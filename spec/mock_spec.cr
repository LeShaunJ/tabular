require "./spec_helper"

Spectator.describe Tabular, :library, :cli do
  def run(args : Array(String))
    args = %w(__complete).concat(args)
    proc = Process.new "bin/cli", args, output: PIPE
    stdout = proc.output.gets_to_end
    status = proc.wait

    stdout
  end

  def self.command_lines
    [
      {["-"], "eq", "--environment\n--env\n-e\n:4\n"},
      {["--env"], "eq", "--environment\n--env\n:4\n"},
      {["--enviro"], "eq", "--environment\n:4\n"},
      {["--environment", ""], "eq", "dev\nci\nstaging\nproduction\n:0\n"},
      {["--env="], "eq", "--env=dev\n--env=ci\n--env=staging\n--env=production\n:0\n"},
      {["--env=d"], "eq", "--env=dev\n:0\n"},
      {["--env=c"], "eq", "--env=ci\n:0\n"},
      {["--env=s"], "eq", "--env=staging\n:0\n"},
      {["--env=p"], "eq", "--env=production\n:0\n"},
      {["-e", "dev", ""], "match", /apply\t.+\na\t.+\nrun\t.+\nr\t.+\ndestroy\t.+\nd\t.+\n:4/},
      {["apply", "--file", ""], "eq", "yaml\nyml\n:8\n"},
      {["apply", "--file="], "eq", "yaml\nyml\n:8\n"},
      {["apply", "--file=yaml"], "eq", "yaml\nyml\n:8\n"},
      {["apply", "--file=yml"], "eq", "yaml\nyml\n:8\n"},
      {["run", ""], "eq", "::\n:64\n"},
    ]
  end

  sample command_lines do |args, matcher, result|
    it "completes as expected" do
      case matcher
      when "eq"
        expect(run(args)).to eq(result)
      when "match"
        expect(run(args)).to match(result)
      end
    end
  end
end
