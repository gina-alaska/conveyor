app = proc do |env|
  content = File.read('public/index.html')
  [
    200,
    { 'Content-Type' => 'text/html', 'Content-Length' => content.length.to_s },
    [content]
  ]
end

run app
