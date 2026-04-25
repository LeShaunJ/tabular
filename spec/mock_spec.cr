require "./spec_helper"
require "../src/tabular/shell"

BIN_PATH = Path["#{__DIR__}/../bin"].normalize.to_s

Spectator.describe Tabular::Shell, :library, :cli do
  def self.expressions
    Tabular::Shell.values.cartesian_product([
      {["-"], "match", [/--environment\b/, /--env\b/]},
      {["--env"], "match", [/--environment\b/, /--env\b/]},
      {["--enviro"], "eq", ["--environment\n"]},
      {["--environment", ""], "match", [/\bdev\b/, /\bci\b/, /\bstaging\b/, /\bproduction\b/]},
      {["--env="], "match", [/\bdev\b/, /\bci\b/, /\bstaging\b/, /\bproduction\b/]},
      {["--env=d"], "match", [/\bdev$/]},
      {["--env=c"], "match", [/\bci$/]},
      {["--env=s"], "match", [/\bstaging$/]},
      {["--env=p"], "match", [/\bproduction$/]},
      {["-e", "dev", ""], "match", [/^a\s.+\napply\s.+\n/m,
                                    /^completion\s.+\n/m,
                                    /^d\s.+\ndestroy\s.+\n/m,
                                    /^e\s.+\nexec\s.+\n/m,
                                    /^r\s.+\nrun\s.+\n/m]},
      {["apply", "--file", ""], "match", [/\.ya?ml\b/]},
      {["apply", "--file="], "match", [/\.ya?ml\b/]},
      {["completion", ""], "match", [/\bbash\b/, /\bfish\b/, /\bzsh\b/]},
      {["destroy", "-N", ""], "match", [/\bbin\/?\b/, /\bspec\/?\b/, /\bsrc\/?\b/]},
      {["destroy", "-N", "bin", ""], "match", [/\bbin\/?\b/, /\bspec\/?\b/, /\bsrc\/?\b/]},
      {["exec", "sh"], "match", [/\bsh\b/]},
      {["exec", "cli2", "-"], "match", [/--environment\b/, /--env\b/]},
      {["run", "sh"], "match", [/\bsh\b/]},
      {["run", "cli2", "-"], "match", [/--environment\b/, /--env\b/]},
      {["crap"], "match", [/^$/]},
      {["crap", ""], "match", [/^$/]},
    ]).map do |shell, args|
      {shell, *args}
    end
  end

  sample expressions do |shell, args, operator, condition|
    subject(comps) { shell.simulate args, "cli1", "cli2", paths: [BIN_PATH] }

    it "completes as expected", shell.to_sym do
      condition.each do |pattern|
        case operator
        when "eq"
          expect(comps).to eq(pattern)
        when "match"
          expect(comps).to match(pattern)
        end
      end
    end
  end
end
