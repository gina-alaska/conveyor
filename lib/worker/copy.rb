module Worker
  class Copy < Base
    def diff
      puts "Diffing #{from} #{to}"
      system("diff -N #{from} #{to}")
    end

    def run
      puts "Copying #{from} to #{to}"
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.cp(from, to)
    end
  end
end