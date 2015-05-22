require! {
  parse: "csv-parse"
  fs
}
stream = fs.createReadStream "#__dirname/../data/teplice_odtahy.csv"
reader = parse {delimiter: ','}
stream.pipe reader

minX = Infinity
maxX = -Infinity

minY = Infinity
maxY = -Infinity

reader.on \data (line) ->
  [..._,typ,x,y] = line
  return if x == 'x'
  x = parseFloat x
  y = parseFloat y
  return unless x and y
  minX := x if x < minX
  maxX := x if x > maxX
  minY := y if y < minY
  maxY := y if y > maxY

<~ reader.on \end

console.log minX, maxX, minY, maxY
