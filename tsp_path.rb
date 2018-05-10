require 'json'
require 'geokit'
require 'test/unit'

class DeliveryMan 
 
  def initialize(speed=60, unit="km", breweries=[], origin )
    @speed = speed
    @distance_unit = unit
    @speed_unit = unit
    @breweries = breweries
    @origin = origin
    @calculated_path = nil
  end

  def calculate
    raise "Must be origin specified " if @origin.nil?
    @calculated_path if @calculated_path
    visited = [ @origin ]
    un_visited = @breweries["features"].select{|t| t != @origin }
    self.calculate_distance_matrix()
    until un_visited == [] do
      node = shortest_distance_to(visited.last,un_visited)
      insert_into(node,visited)
    end
    @calculated_path = visited
    {
      result: @calculated_path,
      estimate_time: self.time_to_go(),
      total_distance: self.total_distance().round(2),
      speed: @speed,
      distance_unit: @distance_unit,
      speed_unit: @speed_unit
    }
  end

  def total_distance
    sum = 0
    origin = @calculated_path.first
    (@calculated_path.length-1).times do |t|
      sum += @calculated_path[t+1]["location"].distance_to(origin["location"])
      origin = @calculated_path[t+1]
    end
    sum
  end

  def time_to_go(units="minutes")
    case units.to_sym
    when :minutes
      self.total_distance().round(2) 
    when :hours
      (self.total_distance()/(60/60)).round(2)
    else
      self.total_distance().round(2)
    end
  end 

  def path_with_index
    @breweries.map{|t| "#{t['properties']['name']}, index:#{t['index']}" }.join(" -> ")
  end

  def path_with_distance
    origin = @breweries[0]
    @breweries.each do |next_node|
      puts "#{next_node['location'].distance_to(origin['location'])}km #{next_node['properties']['name']}  -> "
      origin = next_node
    end
  end

  def path_to_travel
    @calculated_path
  end

protected

  def calculate_distance_matrix()
    if !@breweries.nil?
      @edge = @breweries["features"].map{|b| @breweries["features"].map{|d| b["location"].distance_to(d["location"],units: :kms)}}
    end
  end

  def shortest_distance_to(from, adjs)
    array_min = adjs.map.with_index{ |a,i| { distance: a["location"].distance_to(from["location"]), index: i } }.sort_by{|c| c[:distance] }
    adjs.delete_at(array_min.first[:index])
  end

  def insert_into(node,trave)
    if trave.count < 2
      trave << node
    else
      middle = []
      (trave.count - 1).times do |i|
        middle << { 
         sum: @edge[trave[i]["index"]][node["index"]] + @edge[node["index"]][trave[i+1]["index"]] - @edge[trave[i]["index"]][trave[i+1]["index"]],
         to: trave[i]["index"],
         next: trave[i+1]["index"]
       }
      end
      middle_node = middle.sort_by{|m| m[:sum]}.first
      next_node = trave.delete(trave.select{ |t| t[:index] == middle_node["next"] }.first)
      trave.insert(trave.index(trave.select{ |t| t[:index] == middle_node["to"]}.first),node )
      trave.insert(trave.index(node),next_node)
    end
    trave
  end
end