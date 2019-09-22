# gem install daru daru-view

require "daru"

df = Daru::DataFrame.new(
  {
    "Cat Names" => %w(Kitty Leo Felix),
    "Weight"   => [2,3,5]
  }
)

df.plot(type: :bar, x: "Cat Names", y: "Weight") do |plot, _|
  plot.x_label "Cat Name"
  plot.y_label "Weight"

  plot.yrange [0, 5]
end.export_html
