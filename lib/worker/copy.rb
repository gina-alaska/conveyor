class Worker::BarrowWebcam < Base
  def run
    puts "Copying #{from} to #{to}"
    FileUtils.mkdir_p(File.dirname(to))
    FileUtils.cp(from, to)
  end
end