require 'json'
require 'geokit'
require 'test/unit'
require_relative 'tsp_path'

class DeliveryManTest < Test::Unit::TestCase
  def setup
    # Delivery Man start to Mundo 2150 
    #
    @json_breweries = JSON.parse(File.read("./breweries.geojson"))
    @json_breweries["features"].map.with_index do |brewery,index|
      brewery["location"] =  Geokit::LatLng.new(brewery["geometry"]["coordinates"][0],brewery["geometry"]["coordinates"][1])
      brewery["index"] = index
    end

    @delivery_man = DeliveryMan.new(60,:km,@json_breweries,@json_breweries["features"][0])
    @delivery_man.calculate()
  end

  test "short path distance for challenge" do
    assert_equal @delivery_man.total_distance.round(2), 38.14
  end

  test "time to finish challenge" do
    assert_equal @delivery_man.time_to_go, 38.14
  end

  test "path to travel" do
    indexes_breweries = [0, 11, 8, 5, 13, 10, 12, 3, 9, 16, 14, 4, 15, 6, 7, 1, 2, 18, 17, 19]
    assert_equal @delivery_man.path_to_travel.map{|r| r["index"]}, indexes_breweries
  end

  test "Delivery Man start to Mundo 2150" do
    assert_equal @delivery_man.calculate[:result][0]["properties"]["name"], "Mundo 2150"
  end
end

